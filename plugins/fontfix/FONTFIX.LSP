;;; 作者：Ccwtpot
;;; FONTFIX - 全图+手动双模式（2018/2024通用，静默执行-style）
(defun c:FONTFIX (/ process-mode ss ename textdata count total success new-textdata x)
    ;; 1. 强制加载VL库（解决2024 vl-cmdf未定义）
    (vl-load-com)
    ;; 2. 错误处理（保留核心，不影响修改）
    (setq *old-error* *error*)
    (defun *error* (msg)
        (princ (strcat "\n【错误】: " msg))
        (setq *error* *old-error*)
        (princ)
    )

    ;; 3. 模式选择（A=全图/S=选择，默认A）
    (princ "\n=== MTEXT专属修复（全图+手动双模式）===")
    (setq process-mode (getkword "\n处理模式 [A=全图/S=手动选择] <A>: "))
    (if (not process-mode) (setq process-mode "A")) ; 默认全图

    ;; 4. 关闭文字快速显示（vl-cmdf静默执行，无交互）
    (vl-cmdf "qtext" "off")

    ;; 5. 按模式选择文本（保留原有筛选逻辑）
    (cond
        ((= process-mode "A")
            (princ "\n🔍 全图搜索文本（TEXT/MTEXT）...")
            (setq ss (ssget "X" '((0 . "TEXT,MTEXT"))))
            (if (not ss)
                (progn 
                    (princ "\n❌ 全图未找到TEXT/MTEXT，程序结束。") 
                    (setq *error* *old-error*) 
                    (return nil)
                )
            )
            (setq total (sslength ss))
            (princ (strcat "\n✅ 全图找到 " (itoa total) " 个文本，开始修复..."))
        )
        ((= process-mode "S")
            (princ "\n请框选显示\"?\"的文本（重点选红色问号的MTEXT）...")
            (setq ss (ssget '((0 . "TEXT,MTEXT"))))
            (if (not ss)
                (progn 
                    (princ "\n❌ 未选中文本，程序结束。") 
                    (setq *error* *old-error*) 
                    (return nil)
                )
            )
            (setq total (sslength ss))
            (princ (strcat "\n✅ 选中 " (itoa total) " 个文本，开始修复..."))
        )
    )

    ;; 6. 重置STANDARD样式（vl-cmdf静默执行，补全所有参数，无交互弹窗）
    ;; 核心修复：2024用vl-cmdf避免-style交互，参数补全“是否垂直”的N
    (vl-cmdf "-style" "STANDARD" "gbcbig.shx" "0" "1" "0" "N" "N" "N")

    ;; 7. 批量修复核心逻辑（完全保留原有纯原生代码）
    (setq count 0 success 0)
    (repeat total
        (setq count (1+ count) 
              ename (ssname ss (- count 1)) 
              textdata (entget ename))
        (if (and textdata (listp textdata))
            (progn
                (setq new-textdata nil)
                (foreach x textdata
                    (if (not (member (car x) '(1001 1003)))
                        (setq new-textdata (append new-textdata (list x)))
                    )
                )
                (setq textdata new-textdata)

                (if (assoc 7 textdata)
                    (setq textdata (subst (cons 7 "STANDARD") (assoc 7 textdata) textdata))
                    (setq textdata (append textdata (list (cons 7 "STANDARD"))))
                )

                (if (entmod textdata)
                    (progn (entupd ename) (setq success (1+ success)))
                )
            )
        )
    )

    ;; 8. 原生刷新（保留原有逻辑）
    (command "regen")
    (command "redraw")

    ;; 9. 结果反馈（保留原有逻辑）
    (princ "\n\n========================================")
    (princ (strcat "\n✅ 修复完成！"))
    (princ (strcat "\n📢 处理模式：" (if (= process-mode "A") "全图" "手动选择")))
    (princ (strcat "\n📊 总文本：" (itoa total) " | 成功修复：" (itoa success)))
    (princ "\n🎯 核心效果：文字快速显示已关闭，MTEXT字体已重置")
    (princ "\n========================================\n")

    (setq *error* *old-error*)
    (princ)
)

;; 绑定FF命令（加固2024兼容性）
(defun c:FF () 
    (princ "\n🔧 调用FF命令（全图+手动双模式）...")
    (c:FONTFIX)
)

;; 加载提示（保留原有逻辑）
(princ "\n🎉 双模式修复工具（2018/2024通用）已加载！")
(princ "\n命令：FF / FONTFIX")
(princ "\n模式：默认全图（A），输入S可手动框选\n")
(princ)