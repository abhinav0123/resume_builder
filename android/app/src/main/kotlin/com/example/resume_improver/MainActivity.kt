
package com.example.resume_improver

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SubscriptionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.resume_improver/sim"
    private val REQUEST_CODE = 101

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getSimCards" -> {

                    if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.READ_PHONE_STATE
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        pendingResult = result

                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.READ_PHONE_STATE
                            ),
                            REQUEST_CODE
                        )
                    } else {
                        getSimCards(result)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun getSimCards(result: MethodChannel.Result) {

        try {
            val subscriptionManager =
                getSystemService(
                    TELEPHONY_SUBSCRIPTION_SERVICE
                ) as SubscriptionManager

            val subscriptions =
                subscriptionManager.activeSubscriptionInfoList

            val simList = subscriptions?.map { sim ->

                mapOf(
                    "subscriptionId" to sim.subscriptionId,
                    "slotIndex" to sim.simSlotIndex,
                    "displayName" to sim.displayName.toString(),
                    "carrierName" to sim.carrierName.toString(),
                    "countryIso" to sim.countryIso,
                    "isEmbedded" to sim.isEmbedded
                )

            } ?: emptyList()

            result.success(simList)

        } catch (e: SecurityException) {

            result.error(
                "PERMISSION_DENIED",
                e.message,
                null
            )

        } catch (e: Exception) {

            result.error(
                "SIM_ERROR",
                e.message,
                null
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )

        if (requestCode == REQUEST_CODE) {

            val result = pendingResult
            pendingResult = null

            if (grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            ) {
                result?.let { getSimCards(it) }
            } else {
                result?.error(
                    "PERMISSION_DENIED",
                    "Phone state permission denied",
                    null
                )
            }
        }
    }
}
