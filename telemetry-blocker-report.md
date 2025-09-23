# Windows Telemetry Blocker - Change Report

**Date:** 9/23/2025 1:16:38 PM
**Script Version:** nextgen-0.8-RLS
**Windows Version:** 10.0.26100
**Windows Build:** 26100
**Execution Time:** 00:00:01.3776403

## Modules Run
- misc Error (Start: 9/23/2025 1:16:37 PM, End: 9/23/2025 1:16:37 PM) - Error: At E:\Github\WindowsTelementeryBlocker\modules\misc.ps1:53 char:39
+ Write-ModuleLog "Misc module completed"
+                                       ~
The string is missing the terminator: ".
- telemetry Error (Start: 9/23/2025 1:16:36 PM, End: 9/23/2025 1:16:36 PM) - Error: At E:\Github\WindowsTelementeryBlocker\modules\telemetry.ps1:43 char:1
+ }
+ ~
Unexpected token '}' in expression or statement.
- services Error (Start: 9/23/2025 1:16:37 PM, End: 9/23/2025 1:16:37 PM) - Error: At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:31 char:17
+             try {
+                 ~
Missing closing '}' in statement block or type definition.

At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:47 char:13
+ return $true
+             ~
The Try statement is missing its Catch or Finally block.

At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:30 char:16
+         } else {
+                ~
Missing closing '}' in statement block or type definition.

At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:26 char:61
+     if (Get-Service $service -ErrorAction SilentlyContinue) {
+                                                             ~
Missing closing '}' in statement block or type definition.

At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:25 char:42
+ foreach ($service in $servicesToDisable) {
+                                          ~
Missing closing '}' in statement block or type definition.

## Summary
- ERROR: telemetry : At E:\Github\WindowsTelementeryBlocker\modules\telemetry.ps1:43 char:1
+ }
+ ~
Unexpected token '}' in expression or statement.
- ERROR: services : At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:31 char:17
+             try {
+                 ~
Missing closing '}' in statement block or type definition.

At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:47 char:13
+ return $true
+             ~
The Try statement is missing its Catch or Finally block.

At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:30 char:16
+         } else {
+                ~
Missing closing '}' in statement block or type definition.

At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:26 char:61
+     if (Get-Service $service -ErrorAction SilentlyContinue) {
+                                                             ~
Missing closing '}' in statement block or type definition.

At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:25 char:42
+ foreach ($service in $servicesToDisable) {
+                                          ~
Missing closing '}' in statement block or type definition.
- ERROR: misc : At E:\Github\WindowsTelementeryBlocker\modules\misc.ps1:53 char:39
+ Write-ModuleLog "Misc module completed"
+                                       ~
The string is missing the terminator: ".


## Errors
- 2025-09-23 13:01:16 ERROR in module telemetry : At E:\Github\WindowsTelementeryBlocker\modules\telemetry.ps1:43 char:1
- + }
- + ~
- Unexpected token '}' in expression or statement.
- 2025-09-23 13:02:50 ERROR in module telemetry : At E:\Github\WindowsTelementeryBlocker\modules\telemetry.ps1:43 char:1
- + }
- + ~
- Unexpected token '}' in expression or statement.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\telemetry.ps1:44 char:7
- + catch {
- +       ~
- Missing closing '}' in statement block or type definition.
- 2025-09-23 13:05:50 ERROR in module telemetry : The term 'catch' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
- 2025-09-23 13:05:55 ERROR in module services : At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:30 char:17
- +             try {
- +                 ~
- Missing closing '}' in statement block or type definition.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:45 char:13
- + return $true
- +             ~
- The Try statement is missing its Catch or Finally block.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:29 char:16
- +         } else {
- +                ~
- Missing closing '}' in statement block or type definition.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:25 char:61
- +     if (Get-Service $service -ErrorAction SilentlyContinue) {
- +                                                             ~
- Missing closing '}' in statement block or type definition.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:24 char:42
- + foreach ($service in $servicesToDisable) {
- +                                          ~
- Missing closing '}' in statement block or type definition.
- 2025-09-23 13:05:58 ERROR in module misc : At E:\Github\WindowsTelementeryBlocker\modules\misc.ps1:53 char:39
- + Write-ModuleLog "Misc module completed"
- +                                       ~
- The string is missing the terminator: ".
- 2025-09-23 13:09:02 ERROR in module telemetry : At E:\Github\WindowsTelementeryBlocker\modules\telemetry.ps1:43 char:1
- + } catch {
- + ~
- Unexpected token '}' in expression or statement.
- 2025-09-23 13:09:05 ERROR in module services : At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:30 char:17
- +             try {
- +                 ~
- Missing closing '}' in statement block or type definition.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:45 char:13
- + return $true
- +             ~
- The Try statement is missing its Catch or Finally block.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:29 char:16
- +         } else {
- +                ~
- Missing closing '}' in statement block or type definition.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:25 char:61
- +     if (Get-Service $service -ErrorAction SilentlyContinue) {
- +                                                             ~
- Missing closing '}' in statement block or type definition.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:24 char:42
- + foreach ($service in $servicesToDisable) {
- +                                          ~
- Missing closing '}' in statement block or type definition.
- 2025-09-23 13:09:06 ERROR in module misc : At E:\Github\WindowsTelementeryBlocker\modules\misc.ps1:53 char:39
- + Write-ModuleLog "Misc module completed"
- +                                       ~
- The string is missing the terminator: ".
- 2025-09-23 13:16:36 ERROR in module telemetry : At E:\Github\WindowsTelementeryBlocker\modules\telemetry.ps1:43 char:1
- + }
- + ~
- Unexpected token '}' in expression or statement.
- 2025-09-23 13:16:37 ERROR in module services : At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:31 char:17
- +             try {
- +                 ~
- Missing closing '}' in statement block or type definition.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:47 char:13
- + return $true
- +             ~
- The Try statement is missing its Catch or Finally block.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:30 char:16
- +         } else {
- +                ~
- Missing closing '}' in statement block or type definition.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:26 char:61
- +     if (Get-Service $service -ErrorAction SilentlyContinue) {
- +                                                             ~
- Missing closing '}' in statement block or type definition.
- 
- At E:\Github\WindowsTelementeryBlocker\modules\services.ps1:25 char:42
- + foreach ($service in $servicesToDisable) {
- +                                          ~
- Missing closing '}' in statement block or type definition.
- 2025-09-23 13:16:37 ERROR in module misc : At E:\Github\WindowsTelementeryBlocker\modules\misc.ps1:53 char:39
- + Write-ModuleLog "Misc module completed"
- +                                       ~
- The string is missing the terminator: ".
