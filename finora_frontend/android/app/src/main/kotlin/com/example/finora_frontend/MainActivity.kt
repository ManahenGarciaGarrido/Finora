package com.example.finora_frontend

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val platformVersionChannel = "com.finora.app/platform_version"
    private val widgetChannel = "com.finora.widget/update"
    private val wearableChannel = "com.finora.watch/wearable"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Platform version channel ──────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, platformVersionChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidVersion" -> result.success(Build.VERSION.SDK_INT)
                    "getAndroidVersionName" -> result.success(Build.VERSION.RELEASE)
                    "getDeviceInfo" -> {
                        result.success(mapOf(
                            "apiLevel" to Build.VERSION.SDK_INT,
                            "versionName" to Build.VERSION.RELEASE,
                            "manufacturer" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "device" to Build.DEVICE,
                            "brand" to Build.BRAND,
                            "sdkInt" to Build.VERSION.SDK_INT
                        ))
                    }
                    "isAtLeastVersion" -> {
                        val requiredVersion = call.argument<Int>("version")
                        if (requiredVersion != null) {
                            result.success(Build.VERSION.SDK_INT >= requiredVersion)
                        } else {
                            result.error("INVALID_ARGUMENT", "Version argument is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Widget update channel ─────────────────────────────────────────────
        // Called from Flutter to push financial data to the home screen widget.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        try {
                            @Suppress("UNCHECKED_CAST")
                            val args = call.arguments as? Map<String, Any> ?: emptyMap()
                            val balance = args["balance"] as? String ?: "€0.00"
                            val todaySpent = args["today_spent"] as? String ?: "€0.00"
                            val budgetPct = (args["budget_pct"] as? Number)?.toInt() ?: 0
                            val goalName = args["goal_name"] as? String ?: ""
                            val goalPct = (args["goal_pct"] as? Number)?.toInt() ?: 0
                            val updatedAt = args["updated_at"] as? String ?: ""

                            // Persist data for widget and trigger update
                            FinoraWidget.storeWidgetData(
                                applicationContext,
                                balance, todaySpent, budgetPct,
                                goalName, goalPct, updatedAt
                            )

                            // Force immediate redraw of all FinoraWidget instances
                            val awm = AppWidgetManager.getInstance(applicationContext)
                            val ids = awm.getAppWidgetIds(
                                ComponentName(applicationContext, FinoraWidget::class.java)
                            )
                            if (ids.isNotEmpty()) {
                                val provider = FinoraWidget()
                                provider.onUpdate(applicationContext, awm, ids)
                            }

                            result.success(true)
                        } catch (e: Exception) {
                            result.error("WIDGET_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Wearable channel ──────────────────────────────────────────────────
        // Provides real Wear OS connectivity using the Wearable Data Layer API.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wearableChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkConnection" -> checkWearConnection(result)
                    "pushData" -> {
                        @Suppress("UNCHECKED_CAST")
                        pushDataToWatch(call.arguments as? Map<String, Any>, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Check whether at least one Wear OS node is connected.
     * Returns true/false via [result].
     */
    private fun checkWearConnection(result: MethodChannel.Result) {
        try {
            val wearable = Class.forName("com.google.android.gms.wearable.Wearable")
            val getNodeClient = wearable.getMethod("getNodeClient", Context::class.java)
            val nodeClient = getNodeClient.invoke(null, applicationContext)
            val connectedNodes = nodeClient.javaClass.getMethod("getConnectedNodes")
            val task = connectedNodes.invoke(nodeClient)

            // Add success listener via reflection (Tasks API)
            val addOnSuccessListener = task.javaClass.getMethod(
                "addOnSuccessListener",
                com.google.android.gms.tasks.OnSuccessListener::class.java
            )
            addOnSuccessListener.invoke(task,
                com.google.android.gms.tasks.OnSuccessListener<Any> { nodes ->
                    @Suppress("UNCHECKED_CAST")
                    val nodeList = nodes as? Collection<*>
                    result.success(nodeList?.isNotEmpty() ?: false)
                }
            )

            val addOnFailureListener = task.javaClass.getMethod(
                "addOnFailureListener",
                com.google.android.gms.tasks.OnFailureListener::class.java
            )
            addOnFailureListener.invoke(task,
                com.google.android.gms.tasks.OnFailureListener {
                    result.success(false)
                }
            )
        } catch (e: ClassNotFoundException) {
            // Wearable SDK not available on this device
            result.success(false)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    /**
     * Push financial summary data to all connected Wear OS nodes.
     * Returns true if data was sent to at least one node.
     */
    private fun pushDataToWatch(args: Map<String, Any>?, result: MethodChannel.Result) {
        try {
            val payload = args?.entries?.joinToString(";") { "${it.key}=${it.value}" }
                ?: "balance=0"
            val payloadBytes = payload.toByteArray(Charsets.UTF_8)

            val wearable = Class.forName("com.google.android.gms.wearable.Wearable")
            val getNodeClient = wearable.getMethod("getNodeClient", Context::class.java)
            val nodeClient = getNodeClient.invoke(null, applicationContext)
            val connectedNodes = nodeClient.javaClass.getMethod("getConnectedNodes")
            val task = connectedNodes.invoke(nodeClient)

            val addOnSuccessListener = task.javaClass.getMethod(
                "addOnSuccessListener",
                com.google.android.gms.tasks.OnSuccessListener::class.java
            )
            addOnSuccessListener.invoke(task,
                com.google.android.gms.tasks.OnSuccessListener<Any> { nodes ->
                    @Suppress("UNCHECKED_CAST")
                    val nodeList = nodes as? Collection<*>
                    if (nodeList.isNullOrEmpty()) {
                        result.success(false)
                        return@OnSuccessListener
                    }

                    val getMessageClient =
                        wearable.getMethod("getMessageClient", Context::class.java)
                    val msgClient = getMessageClient.invoke(null, applicationContext)
                    val sendMessage = msgClient.javaClass.getMethod(
                        "sendMessage", String::class.java, String::class.java, ByteArray::class.java
                    )

                    nodeList.forEach { node ->
                        val nodeId = node?.javaClass?.getMethod("getId")?.invoke(node) as? String
                        if (nodeId != null) {
                            sendMessage.invoke(msgClient, nodeId, "/finora/update", payloadBytes)
                        }
                    }
                    result.success(true)
                }
            )

            val addOnFailureListener = task.javaClass.getMethod(
                "addOnFailureListener",
                com.google.android.gms.tasks.OnFailureListener::class.java
            )
            addOnFailureListener.invoke(task,
                com.google.android.gms.tasks.OnFailureListener {
                    result.success(false)
                }
            )
        } catch (e: ClassNotFoundException) {
            result.success(false)
        } catch (e: Exception) {
            result.success(false)
        }
    }
}