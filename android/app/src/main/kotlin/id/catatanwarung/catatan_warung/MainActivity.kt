package id.catatanwarung.catatan_warung

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result? = null
    private var output: ByteArray? = null
    private var readLimit = 100 * 1024 * 1024
    private val alias = "catatan-warung-backup-wrapper-v1"

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "id.catatanwarung/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "privatePath" -> result.success(noBackupFilesDir.absolutePath)
                "readKey" -> background(result) {
                    val file = File(noBackupFilesDir, "backup-key.bin")
                    if (!file.exists()) null else {
                        try {
                            val data = file.readBytes()
                            require(data.size in 29..8192)
                            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                            cipher.init(Cipher.DECRYPT_MODE, wrappingKey(), GCMParameterSpec(128, data.copyOfRange(0, 12)))
                            String(cipher.doFinal(data.copyOfRange(12, data.size)), Charsets.UTF_8)
                        } catch (_: Exception) { null }
                    }
                }
                "saveKey" -> background(result) {
                    val text = call.argument<String>("value") ?: error("missing key")
                    require(text.length <= 4096)
                    val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                    cipher.init(Cipher.ENCRYPT_MODE, wrappingKey())
                    val bytes = cipher.iv + cipher.doFinal(text.toByteArray(Charsets.UTF_8))
                    val temp = File(noBackupFilesDir, "backup-key.tmp")
                    temp.outputStream().use { it.write(bytes); it.fd.sync() }
                    check(temp.renameTo(File(noBackupFilesDir, "backup-key.bin")))
                    null
                }
                "openDocument", "saveDocument" -> {
                    if (pending != null) result.error("BUSY", "Pemilih file masih terbuka.", null)
                    else {
                        pending = result
                        val saving = call.method == "saveDocument"
                        output = if (saving) call.argument<ByteArray>("bytes") else null
                        readLimit = (call.argument<Int>("maxBytes") ?: (100 * 1024 * 1024)).coerceIn(1, 100 * 1024 * 1024)
                        val intent = Intent(if (saving) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = if (saving) call.argument<String>("mime") ?: "application/octet-stream" else "*/*"
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                            if (saving) putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "catatan.catatanwarung")
                        }
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, if (saving) 901 else 902)
                        } catch (_: Exception) {
                            pending = null; output = null
                            result.error("PICKER", "Pemilih file tidak tersedia pada perangkat ini.", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun wrappingKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256).build())
        return generator.generateKey()
    }

    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        worker.execute {
            try {
                val value = block()
                runOnUiThread { result.success(value) }
            } catch (_: Exception) {
                runOnUiThread { result.error("FILE", "File tidak dapat disimpan atau diverifikasi. Periksa ruang penyimpanan dan coba lagi.", null) }
            }
        }
    }

    private fun readBounded(uri: Uri, limit: Int): ByteArray {
        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input)
            val bytes = ByteArrayOutputStream()
            val buffer = ByteArray(8192)
            var total = 0
            while (true) {
                val length = input.read(buffer)
                if (length < 0) break
                total += length
                require(total <= limit)
                bytes.write(buffer, 0, length)
            }
            return bytes.toByteArray()
        }
    }

    @Deprecated("Activity result bridge for Flutter document picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 901 && requestCode != 902) return
        val result = pending ?: return
        val bytes = output
        pending = null; output = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(if (requestCode == 901) false else null)
            return
        }
        background(result) {
            if (requestCode == 902) readBounded(uri, readLimit)
            else {
                requireNotNull(bytes)
                require(bytes.size <= 100 * 1024 * 1024)
                contentResolver.openOutputStream(uri, "wt").use { stream ->
                    requireNotNull(stream)
                    stream.write(bytes); stream.flush()
                }
                val verified = readBounded(uri, bytes.size)
                val digest = MessageDigest.getInstance("SHA-256")
                check(MessageDigest.isEqual(digest.digest(bytes), digest.digest(verified)))
                true
            }
        }
    }
}
