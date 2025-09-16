import Foundation
import UIKit

class PerformanceMonitor {
    
    // MARK: - Memory Usage
    static func memoryUsage() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)

        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            return info.phys_footprint // in bytes
        } else {
            return 0
        }
    }
    
    // MARK: - Total Memory
    static func totalMemory() -> UInt64 {
        return ProcessInfo.processInfo.physicalMemory
    }
    
    // MARK: - Available Memory
    static func availableMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return totalMemory() - UInt64(info.resident_size)
        } else {
            return totalMemory() / 2 // Fallback estimate
        }
    }
    
    // MARK: - CPU Usage
    static func cpuUsage() -> Double {
        var kr: kern_return_t
        var task_info_count: mach_msg_type_number_t
        
        task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
        var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))

        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count)
        if kr != KERN_SUCCESS {
            return 0.0
        }

        var thread_list: thread_act_array_t? = UnsafeMutablePointer(mutating: [thread_act_t]())
        var thread_count: mach_msg_type_number_t = 0
        defer {
            if let thread_list = thread_list {
                vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: thread_list)), vm_size_t(thread_count))
            }
        }

        kr = task_threads(mach_task_self_, &thread_list, &thread_count)

        if kr != KERN_SUCCESS {
            return 0.0
        }

        var tot_cpu: Double = 0
        
        if let thread_list = thread_list {
            for j in 0 ..< Int(thread_count) {
                var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
                var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))
                kr = thread_info(thread_list[j], thread_flavor_t(THREAD_BASIC_INFO),
                                &thinfo, &thread_info_count)
                if kr != KERN_SUCCESS {
                    return 0.0
                }

                let threadBasicInfo = convertThreadInfoToThreadBasicInfo(thinfo)

                if threadBasicInfo.flags != TH_FLAGS_IDLE {
                    tot_cpu += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
                }
            }
        }

        return tot_cpu
    }
    
    // MARK: - Helper function
    private static func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
        var result = thread_basic_info()
        
        result.user_time = time_value_t(seconds: threadInfo[0], microseconds: threadInfo[1])
        result.system_time = time_value_t(seconds: threadInfo[2], microseconds: threadInfo[3])
        result.cpu_usage = threadInfo[4]
        result.policy = threadInfo[5]
        result.run_state = threadInfo[6]
        result.flags = threadInfo[7]
        result.suspend_count = threadInfo[8]
        result.sleep_time = threadInfo[9]
        
        return result
    }
    
    // MARK: - System Info
    static func systemInfo() -> [String: Any] {
        let usedMemory = memoryUsage()
        let totalMemory = totalMemory()
        let availableMemory = availableMemory()
        let cpuUsage = cpuUsage()
        
        return [
            "usedMemoryBytes": usedMemory,
            "totalMemoryBytes": totalMemory,
            "availableMemoryBytes": availableMemory,
            "usedMemoryMB": Double(usedMemory) / (1024 * 1024),
            "totalMemoryMB": Double(totalMemory) / (1024 * 1024),
            "availableMemoryMB": Double(availableMemory) / (1024 * 1024),
            "memoryUsagePercent": Double(usedMemory) / Double(totalMemory) * 100.0,
            "cpuUsagePercent": cpuUsage,
            "processorCount": ProcessInfo.processInfo.processorCount
        ]
    }
}