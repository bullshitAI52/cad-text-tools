;;;--------------------------------------------------
;;; MT2CSV.lsp - 导出CAD文字到CSV（支持双排序模式）
;;; 版本：v4.1 - 2025.03
;;; 功能：支持选择顺序/坐标排序，增强兼容性
;;;--------------------------------------------------

(defun get-time-string ()
  (menucmd "M=$(edtime,$(getvar,date),YYYYMMDD-HHmmss)")
)

;; MTEXT格式清洗函数（保留原始换行符）
(defun clean-mtext (str / len newstr i skip mode)
  (setq len (strlen str)
        newstr ""
        i 1
        skip 0
        mode nil)
  (while (<= i len)
    (cond
      ((= skip 1) 
        (setq skip 0)
        (setq i (1+ i))
      )
      
      ;; 处理转义字符
      ((and (= (substr str i 1) "\\") (null mode))
        (setq c (substr str (1+ i) 1))
        (cond
          ((member c '("P" "p")) ; 换行符处理
            (setq newstr (strcat newstr "\n"))
            (setq skip 1)
            (if (= (substr str (1+ i) 3) "par")
              (setq i (+ i 3))
              (setq i (1+ i))
            )
          )
          (t ; 跳过格式代码
            (setq mode t)
            (setq i (1+ i))
          )
        )
      )
      
      ;; 跳过格式代码段
      (mode
        (if (member (substr str i 1) '(";" " " "\\"))
          (progn
            (setq mode nil)
            (if (= (substr str i 1) "\\") 
              (setq newstr (strcat newstr "\\"))
            )
          )
        )
        (setq i (1+ i))
      )
      
      ;; 正常字符处理
      (t
        (setq char (substr str i 1))
        (cond
          ((member char '("{" "}")) nil)
          (t (setq newstr (strcat newstr char)))
        )
        (setq i (1+ i))
      )
    )
  )
  newstr
)

;; 主程序（支持双排序模式）
(defun c:MT2CSV (/ *error* ss csvFile path sortMode entList cnt wsh desktop)
  (vl-load-com)
  
  ;; 错误处理函数
  (defun *error* (msg)
    (if (wcmatch msg "函数已取消") 
      (princ "\n命令已取消。")
      (princ (strcat "\n[系统错误] " msg))
    )
    (if (and csvFile (eq 'file (type csvFile))) (close csvFile))
    (if (and wsh (not (vlax-object-released-p wsh)))
      (vlax-release-object wsh)
    )
    (setq entList nil)
    (princ)
  )
  
  ;; 用户选择排序方式
  (initget "XY Select")
  (setq sortMode (getkword "\n选择排序方式回车默认为Select [XY(XY轴)/Select(选择顺序)] <XY>: "))
  (if (null sortMode) (setq sortMode "Select"))
  
  ;; 中文路径处理
  (setq wsh (vlax-create-object "WScript.Shell"))
  (setq desktop 
    (vl-catch-all-apply
      '(lambda ()
         (vlax-get-property 
           (vlax-get-property wsh 'SpecialFolders)
           'Item "Desktop"
         )
       )
    )
  )
  (vlax-release-object wsh)
  (setq wsh nil)

  ;; 桌面路径备选方案
  (if (or (vl-catch-all-error-p desktop) (null desktop))
    (setq desktop (strcat (getenv "USERPROFILE") "\\Desktop"))
  )

  ;; 生成文件路径
  (setq path (strcat desktop "\\文本导出_" (get-time-string) ".csv"))

  ;; 主处理流程
  (if (setq ss (ssget '((0 . "MTEXT,TEXT"))))
    (progn
      ;; 构建实体列表
      (setq entList
        (vl-remove nil
          (mapcar 
            '(lambda (i)
               (if (ssname ss i)
                 (vl-catch-all-apply 'vlax-ename->vla-object (list (ssname ss i)))
               )
             )
            (vl-remove-if-not 
              '(lambda (x) (ssname ss x)) 
              (number-list 0 (1- (sslength ss)))
            )
          )
        )
      )
      
      ;; 按坐标排序处理
      (if (= sortMode "XY")
        (progn
          (princ "\n正在排序坐标...")
          ;; 创建坐标-实体关联列表
          (setq entList
            (mapcar 'cadr
              (vl-sort
                (vl-remove nil
                  (mapcar 
                    '(lambda (obj)
                       (if (and obj (not (vlax-erased-p obj)))
                         (list 
                           (vlax-get-property obj 'InsertionPoint)
                           obj
                         )
                       )
                     )
                    entList
                  )
                )
                '(lambda (a b / ptA ptB)
                   (setq ptA (vlax-safearray->list (vlax-variant-value (car a)))
                         ptB (vlax-safearray->list (vlax-variant-value (car b))))
                   (or
                     (> (cadr ptA) (cadr ptB)) ; Y降序
                     (and 
                       (= (cadr ptA) (cadr ptB))
                       (< (car ptA) (car ptB))  ; X升序
                     )
                   )
                 )
              )
            )
          )
          (princ "完成。")
        )
      )

      ;; 创建CSV文件
      (if (not (setq csvFile (open path "w")))
        (progn
          (princ "\n错误：文件创建失败")
          (exit)
        )
      )
      
      ;; 写入标题行
      (write-line 
        (if (= sortMode "XY") 
          "XY轴排序,X,Y,Z,文本内容" 
          "选择排序,X,Y,Z,文本内容"
        ) 
        csvFile
      )
      (setq cnt 0)
      
      ;; 遍历处理实体
      (foreach ent entList
        (cond
          ((vlax-erased-p ent)
            (princ "\n警告：实体已被删除，跳过处理"))
          
          ((and ent 
                (vlax-property-available-p ent 'InsertionPoint)
                (vlax-property-available-p ent 'TextString)
           )
            (setq cnt (1+ cnt))
            
            ;; 坐标获取
            (setq insPt (vlax-get-property ent 'InsertionPoint))
            (setq pt 
              (if (= (type insPt) 'variant)
                (vlax-safearray->list (vlax-variant-value insPt))
                '(0.0 0.0 0.0)
              )
            )
            
            ;; 坐标格式化
            (setq x (rtos (nth 0 pt) 2 3))
            (setq y (rtos (nth 1 pt) 2 3))
            (setq z (rtos (nth 2 pt) 2 3))
            
            ;; 文本处理
            (setq txtStr (vl-catch-all-apply 'vla-get-TextString (list ent)))
            (if (vl-catch-all-error-p txtStr)
              (setq txtStr "**ERROR**")
              (progn
                (setq txtStr (clean-mtext txtStr))
                ;; 转义处理
                (setq txtStr (vl-string-subst "\"\"" "\"" txtStr))
                ;; 智能包裹
                (if (or (vl-string-search "," txtStr)
                        (vl-string-search "\"" txtStr)
                        (vl-string-search "\n" txtStr))
                  (setq txtStr (strcat "\"" txtStr "\""))
                )
              )
            )
            
            ;; 写入数据行
            (write-line 
              (strcat (itoa cnt) "," x "," y "," z "," txtStr) 
              csvFile
            )
          )
          (t (princ "\n警告：无效实体已跳过"))
        )
      )
      
      ;; 完成操作
      (close csvFile)
      (startapp "explorer" (strcat "/select,\"" path "\"")) 
      (princ (strcat "\n导出成功！处理 " (itoa cnt) "/" (itoa (length entList)) " 个文本"path))
    )
    (princ "\n取消：未选择文字对象！")
  )
  (princ)
)

;;--------------------------------------------------
;; 辅助函数
(defun number-list (start end)
  (if (> start end)
    nil
    (cons start (number-list (1+ start) end))
  )
)