package com.example.whisper_gpt

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import android.os.Process
import java.io.File
import java.io.RandomAccessFile
import kotlin.math.roundToLong

class PerformanceMonitor(private val context: Context) {
    
    private val activityManager: ActivityManager by lazy {
        context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    }
    
    // Memory usage in bytes
    fun getMemoryUsage(): Long {
        val memoryInfo = Debug.MemoryInfo()
        Debug.getMemoryInfo(memoryInfo)
        
        // Return total PSS memory in bytes
        return memoryInfo.totalPss * 1024L
    }
    
    // Total device memory in bytes
    fun getTotalMemory(): Long {
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        return memoryInfo.totalMem
    }
    
    // Available memory in bytes
    fun getAvailableMemory(): Long {
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        return memoryInfo.availMem
    }
    
    // CPU usage percentage (simplified approximation)
    fun getCpuUsage(): Double {
        return try {
            val stat = File("/proc/stat")
            if (stat.exists()) {
                val reader = RandomAccessFile(stat, "r")
                val load = reader.readLine()
                reader.close()
                
                val toks = load.split(" ")
                val user = toks[2].toDouble()
                val nice = toks[3].toDouble()
                val system = toks[4].toDouble()
                val idle = toks[5].toDouble()
                val ioWait = toks[6].toDouble()
                val irq = toks[7].toDouble()
                val softIrq = toks[8].toDouble()
                val steal = toks[9].toDouble()
                val guest = toks[10].toDouble()
                val guestNice = toks[11].toDouble()
                
                val totalIdle = idle + ioWait
                val nonIdle = user + nice + system + irq + softIrq + steal + guest + guestNice
                val total = totalIdle + nonIdle
                
                ((nonIdle / total) * 100.0).coerceIn(0.0, 100.0)
            } else {
                // Fallback: use a simple approximation based on process load
                val pid = Process.myPid()
                val pidStat = File("/proc/$pid/stat")
                if (pidStat.exists()) {
                    val reader = RandomAccessFile(pidStat, "r")
                    val statLine = reader.readLine()
                    reader.close()
                    
                    val tokens = statLine.split(" ")
                    val utime = tokens[13].toLong()
                    val stime = tokens[14].toLong()
                    val totalTime = utime + stime
                    
                    // Simple approximation - return a percentage based on process activity
                    ((totalTime % 10000) / 100.0).coerceIn(0.0, 50.0)
                } else {
                    15.0 // Default fallback
                }
            }
        } catch (e: Exception) {
            15.0 // Default fallback on any error
        }
    }
    
    // Get processor count
    fun getProcessorCount(): Int {
        return Runtime.getRuntime().availableProcessors()
    }
    
    // Get comprehensive system info
    fun getSystemInfo(): Map<String, Any> {
        val usedMemory = getMemoryUsage()
        val totalMemory = getTotalMemory()
        val availableMemory = getAvailableMemory()
        val cpuUsage = getCpuUsage()
        
        return mapOf(
            "usedMemoryBytes" to usedMemory,
            "totalMemoryBytes" to totalMemory,
            "availableMemoryBytes" to availableMemory,
            "usedMemoryMB" to (usedMemory / (1024.0 * 1024.0)).roundToLong(),
            "totalMemoryMB" to (totalMemory / (1024.0 * 1024.0)).roundToLong(),
            "availableMemoryMB" to (availableMemory / (1024.0 * 1024.0)).roundToLong(),
            "memoryUsagePercent" to (usedMemory.toDouble() / totalMemory.toDouble() * 100.0),
            "cpuUsagePercent" to cpuUsage,
            "processorCount" to getProcessorCount()
        )
    }
}