;;; EXPLODEATT 批量处理版 - 可选择处理后续图块
;;; 作者: Ccwtpot
;;; 版本: 6.0 - 批量处理版
;;; 功能: 可选择处理当前图块及后续所有图块，保留边框，隐藏原始属性，缩小文本

(defun c:EXPLODEATT (/ ss count ename blkdata blkname target-ename target-handle process-all)
  ;; 保存原始错误处理
  (setq *old-error* *error*)

  (defun *error* (msg)
    (princ (strcat "\n错误: " msg))
    (setq *error* *old-error*)
    (princ)
  )

  (princ "\n=== AutoLISP属性炸开工具 - 批量处理版 ===")
  
  ;; 询问用户是否处理后续所有图块
  (setq process-all (getstring "\n是否处理后续所有图块? (Y/N): "))
  (setq process-all (or (= (strcase process-all) "Y") (= (strcase process-all) "YES")))

  ;; 选择图块（仅允许选择INSERT实体）
  (princ "\n请选择要炸开属性的图块: ")
  (setq ss (ssget '((0 . "INSERT"))))
  (if (not ss)
      (progn (princ "\n未选择任何对象，程序退出。")
             (princ)
             (exit)
      )
  )

  (setq count 0)
  (setq total-count 0)

  ;; 遍历选择的每个图块
  (repeat (sslength ss)
    (setq ename (ssname ss count))
    (process-single-block ename)
    (setq count (1+ count))
    (setq total-count (1+ total-count))

    ;; 如果选择处理后续图块，则继续遍历
    (if process-all
        (progn
          (setq next-ename (entnext ename))
          (while next-ename
            (setq next-data (entget next-ename))
            (if (and next-data (= (cdr (assoc 0 next-data)) "INSERT"))
                (progn
                  (process-single-block next-ename)
                  (setq total-count (1+ total-count))
                )
            )
            (setq next-ename (entnext next-ename))
          )
        )
    )
  )

  (princ (strcat "\n\n========================================"))
  (princ (strcat "\n全部处理完成！共处理 " (itoa total-count) " 个图块"))
  (princ "\n使用说明: 可选择处理当前图块及后续所有图块")
  (princ "\n========================================\n")

  (setq *error* *old-error*)
  (princ)
)

;; 处理单个图块的函数
(defun process-single-block (ename / blkdata blkname target-ename target-handle attcount)
  (setq blkdata (entget ename))
  (if (not blkdata)
      (return nil)
  )

  ;; 获取关键信息
  (setq blkname (cdr (assoc 2 blkdata)))
  (setq target-ename ename)
  (setq target-handle (cdr (assoc 5 blkdata)))

  (princ (strcat "\n\n========================================"))
  (princ (strcat "\n正在处理图块: " blkname))
  (princ (strcat "\n图元名: " (vl-princ-to-string target-ename)))
  (princ (strcat "\n句柄: " target-handle))
  (princ "\n----------------------------------------")

  ;; 处理属性（仅保留可见属性）
  (setq attcount (process-attributes target-ename target-handle))

  (princ (strcat "\n----------------------------------------"))
  (princ (strcat "\n图块处理完成: " blkname))
  (if (= attcount 0)
      (princ "\n未找到任何有效可见属性")
      (princ (strcat "\n成功创建 " (itoa attcount) " 个文本对象（已缩小字号+偏移）"))
  )
)

;; 处理属性：匹配所有者 + 过滤可见性 + 隐藏原始属性
(defun process-attributes (target-ename target-handle / att attdata ent-type att-owner att-visibility attcount)
  (setq att (entnext target-ename))
  (setq attcount 0)

  (while att
    (setq attdata (entget att))
    (if (not attdata)
        (setq att nil)
        (progn
          (setq ent-type (cdr (assoc 0 attdata)))

          (cond
            ;; 处理属性：匹配所有者 + 可见性为0（可见）
            ((= ent-type "ATTRIB")
             (setq att-owner (cdr (assoc 330 attdata)))
             (setq att-visibility (cdr (assoc 60 attdata)))
             (if (not att-visibility) (setq att-visibility 0))

             (princ (strcat "\n找到属性: " (cdr (assoc 2 attdata)) " (所有者: " (vl-princ-to-string att-owner) "，可见性: " (itoa att-visibility) ")"))

             ;; 双重过滤：所有者是目标块 + 属性可见
             (if (and (equal att-owner target-ename) (= att-visibility 0))
                 (progn
                   (princ "\n  ✓ 可见属性，处理中...")
                   ;; 隐藏原始属性
                   (if (entget att)
                       (progn
                         (setq att-data (entget att))
                         (if (assoc 60 att-data)
                             (setq att-data (subst (cons 60 1) (assoc 60 att-data) att-data))
                             (setq att-data (append att-data (list (cons 60 1))))
                         )
                         (entmod att-data)
                         (princ "\n  ✔ 已隐藏原始属性")
                       )
                   )
                   ;; 创建缩放后文本
                   (if (create-text-from-att att)
                       (setq attcount (1+ attcount))
                   )
                 )
                 (princ "\n  ✗ 隐藏属性/非目标块属性，跳过...")
             )
            )

            ;; 处理1层内部块（兼容简单嵌套）
            ((= ent-type "INSERT")
             (princ (strcat "\n发现内部块: " (cdr (assoc 2 attdata)) "，处理其可见属性..."))
             (setq inner-att (entnext att))
             (while (and inner-att (not (= (cdr (assoc 0 (entget inner-att))) "SEQEND")))
               (if (= (cdr (assoc 0 (entget inner-att))) "ATTRIB")
                   (progn
                     (setq inner-att-owner (cdr (assoc 330 (entget inner-att))))
                     (setq inner-att-visibility (cdr (assoc 60 (entget inner-att))))
                     (if (not inner-att-visibility) (setq inner-att-visibility 0))
                     ;; 内部属性：属于内部块 + 可见
                     (if (and (equal inner-att-owner att) (= inner-att-visibility 0))
                         (progn
                           (princ (strcat "\n  内部可见属性: " (cdr (assoc 2 (entget inner-att)))))
                           ;; 隐藏内部原始属性
                           (if (entget inner-att)
                               (progn
                                 (setq inner-att-data (entget inner-att))
                                 (if (assoc 60 inner-att-data)
                                     (setq inner-att-data (subst (cons 60 1) (assoc 60 inner-att-data) inner-att-data))
                                     (setq inner-att-data (append inner-att-data (list (cons 60 1))))
                                 )
                                 (entmod inner-att-data)
                               )
                           )
                           ;; 创建缩放后文本
                           (if (create-text-from-att inner-att)
                               (setq attcount (1+ attcount))
                           )
                         )
                     )
                   )
               )
               (setq inner-att (entnext inner-att))
             )
            )
          )

          ;; 遇到SEQEND停止当前分支
          (if (= ent-type "SEQEND")
              (setq att nil)
              (setq att (entnext att))
          )
        )
    )
  )

  attcount
)

;; 根据属性创建文本（缩小字号+向上偏移）
(defun create-text-from-att (att / attdata insertpt rotation height style color layer attvalue textdata scale-factor)
  (setq attdata (entget att))
  (setq attvalue (cdr (assoc 1 attdata)))

  ;; 跳过空属性
  (if (or (not attvalue) (= attvalue ""))
      (progn (princ "\n  - 跳过空属性")
             (return nil)
      )
  )

  ;; 定义文字缩放因子（可根据需要调整）
  (setq scale-factor 0.7)

  ;; 获取属性几何信息
  (setq insertpt (cdr (assoc 10 attdata)))
  (setq rotation (cdr (assoc 50 attdata)))
  (setq height (cdr (assoc 40 attdata)))
  (setq style (cdr (assoc 7 attdata)))
  (setq color (cdr (assoc 62 attdata)))
  (setq layer (cdr (assoc 8 attdata)))

  ;; 默认值处理
  (if (not rotation) (setq rotation 0.0))
  (if (not height) (setq height 0.25))
  (if (not style) (setq style "STANDARD"))
  (if (not color) (setq color 256))
  (if (not layer) (setq layer "0"))

  ;; 缩小文字高度
  (setq height (* height scale-factor))

  ;; 文本向上偏移1.5倍缩放后字高
  (setq insertpt (list (car insertpt) (+ (cadr insertpt) (* height 0))))

  ;; 创建文本
  (setq textdata (list (cons 0 "TEXT")
                       (cons 1 attvalue)
                       (cons 10 insertpt)
                       (cons 40 height)
                       (cons 50 rotation)
                       (cons 7 style)
                       (cons 62 color)
                       (cons 8 layer)
                       (cons 72 0)  ; 水平左对齐
                       (cons 73 0)  ; 垂直基线对齐
                 )
  )

  (if (entmake textdata)
      (progn (princ (strcat "\n  ✓ 已创建文本: " attvalue " @ " (rtos (car insertpt)) "," (rtos (cadr insertpt))))
             T
      )
      (progn (princ (strcat "\n  ✗ 创建文本失败: " attvalue))
             nil
      )
  )
)


;; ==============================================================================
;; 命令别名定义
;; ==============================================================================
(defun c:XATT (/); 定义一个名为 XATT 的新命令作为别名
    (c:EXPLODEATT) ; 在新命令中调用原来的 EXPLODEATT 命令
)
;; ==============================================================================

(princ "\nEXPLODEATT 批量处理版已加载。")
(princ "\n主命令: EXPLODEATT")
(princ "\n命令别名: XATT")
(princ)