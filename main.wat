(module
  ;; it will be better to pass correct size to module at init time and
  ;; allocate specific amount of memory (grow_memory operator), but...
  ;; ...but this is enough for test and for now. TODO it of course
  (memory $memory 128 128)
  (export "memory" (memory $memory))
  (export "renderChunk" (func $renderChunk))
  
  
  ;; Computes color at position (da, db) with maximum `iters` iterations
  (func $getPixVal (param $da f64) (param $db f64)
                   (param $iters i32) (result f64)
    (local $t f64) (local $aa f64) (local $bb f64)
    (local $a f64) (local $b f64) (local $k i32)
    (set_local $a (get_local $da))
    (set_local $b (get_local $db))
    (set_local $k (get_local $iters))
    
    (block $k_loop_break (loop
      ;; k = k - 1
      (set_local $k (i32.sub (get_local $k) (i32.const 1)))
      
      ;; aa = a*a
      (set_local $aa (f64.mul (get_local $a) (get_local $a)))
      ;; bb = b*b
      (set_local $bb (f64.mul (get_local $b) (get_local $b)))
      
      ;; break if (k <= 0 || aa+bb >= 4)
      (br_if
        $k_loop_break
        (i32.or
          (i32.le_s (get_local $k) (i32.const 0))
          (f64.ge (f64.add (get_local $aa) (get_local $bb))
                  (f64.const 4))
        )
      )
      
      ;; b = 2*a*b + db
      (set_local $b
        (f64.add
          (f64.mul (f64.const 2) (f64.mul (get_local $a) (get_local $b)))
          (get_local $db)
        )
      )
      ;; a = aa - bb + da
      (set_local $a
        (f64.add
          (f64.sub (get_local $aa) (get_local $bb))
          (get_local $da)
        )
      )
      
      (br 0)
    ))
    
    ;; t = k/iters
    (set_local $t
      (f64.div
        (f64.convert_u/i32 (get_local $k))
        (f64.convert_u/i32 (get_local $iters))
      )
    )
    
    ;; pow(t, 16)
    (set_local $t (f64.mul (get_local $t) (get_local $t))) ;;^2
    (set_local $t (f64.mul (get_local $t) (get_local $t))) ;;^4
    (set_local $t (f64.mul (get_local $t) (get_local $t))) ;;^8
    (set_local $t (f64.mul (get_local $t) (get_local $t))) ;;^16
    (get_local $t)
    ;; getPixVal end
  )
  
  
  ;; Computes multiple times color at (da, db) and (h_pix_size, v_pix_size) around it, returns average value
  (func $getSampledPixVal (param $da f64) (param $db f64)
                          (param $h_pix_size f64) (param $v_pix_size f64)
                          (param $iters i32) (result f64)
    (local $i i32) (local $j i32)
    (local $sum f64) (local $o i32) (local $neg_o i32)
    (local $n f64) (local $dh f64) (local $dv f64)

    (set_local $sum (f64.const 0))
    (set_local $o (i32.const 2))
    (set_local $neg_o (i32.sub (i32.const 0) (get_local $o)))
    (set_local $n ;;n=o*2+1
      (f64.convert_u/i32
        (i32.add (i32.mul (get_local $o) (i32.const 2))
                 (i32.const 1))
      )
    )
    (set_local $dh (f64.div (get_local $h_pix_size) (get_local $n))) ;;dh=h_pix_size/n
    (set_local $dv (f64.div (get_local $v_pix_size) (get_local $n))) ;;dv=v_pix_size/n
    
    (set_local $i (get_local $neg_o))
    (loop $i_loop
      
      (set_local $j (get_local $neg_o))
      (loop $j_loop
        
        ;; sum += getPixVal(da+dh*i, db+dv*j, iters)
        (set_local $sum
          (f64.add
            (get_local $sum)
            (call $getPixVal (f64.add (get_local $da) ;;da+dh*i
                                      (f64.mul (get_local $dh)
                                               (f64.convert_s/i32 (get_local $i))))
                             (f64.add (get_local $db) ;;db+dv*j
                                      (f64.mul (get_local $dv)
                                               (f64.convert_s/i32 (get_local $j))))
                             (get_local $iters))
          )
        )
        
        ;; j = j + 1
        (set_local $j (i32.add (get_local $j) (i32.const 1)))
        (br_if 0 (i32.le_s (get_local $j) (get_local $o))) ;;continue if j < o
      )
      
      ;; i = i + 1
      (set_local $i (i32.add (get_local $i) (i32.const 1)))
      (br_if 0 (i32.le_s (get_local $i) (get_local $o))) ;;continue if i < o
    )
    
    (f64.div (get_local $sum) (f64.mul (get_local $n) (get_local $n)))
    ;; getSampledPixVal end
  )
  
  
  ;; Renders fractal chunk into pixel buffer
  ;; width, height - total fractal size in pixels
  ;; xo, yo        - top left chunk position
  ;; w, h          - chunk size
  (func $renderChunk (param $width i32) (param $height i32)
                    (param $xo i32)    (param $yo i32)
                    (param $w i32)     (param $h i32)
    (local $i i32) (local $j i32)
    (local $da f64) (local $db f64)
    
    (local $scale f64) (local $iters i32)
    (set_local $scale (f64.const 2.8))
    (set_local $iters (i32.const 256))
    
    (set_local $i (i32.const 0))
    (loop $i_loop
      
      (set_local $j (i32.const 0))
      (loop $j_loop
        
        ;; da = -(0.73-(xo+i)/width )*scale
        (set_local $da
          (f64.mul
            (f64.sub
              (f64.const 0.73)
              (f64.div
                (f64.convert_u/i32 (i32.add (get_local $xo)
                                            (get_local $i)))
                (f64.convert_u/i32 (get_local $width))
              )
            )
            (get_local $scale)
          )
        )
        ;; db =  (0.5 -(yo+j)/height)*scale
        (set_local $db
          (f64.mul
            (f64.sub
              (f64.const 0.5)
              (f64.div
                (f64.convert_u/i32 (i32.add (get_local $yo)
                                            (get_local $j)))
                (f64.convert_u/i32 (get_local $height))
              )
            )
            (get_local $scale)
          )
        )
        
        ;; pixels[(i+j*w)*4+3] = 255*getSampledPixVal(da, db, scale/width, scale/height, iters)
        (i32.store8
          (i32.add ;;(i+j*w)*4+3
            (i32.mul
              (i32.add
                (get_local $i)
                (i32.mul (get_local $j) (get_local $w))
              )
              (i32.const 4)
            )
            (i32.const 3)
          )
          (i32.trunc_s/f64 ;;255*getSampledPixVal(...)
            (f64.mul
              (f64.const 255)
              (call $getSampledPixVal (f64.neg (get_local $da))
                                      (get_local $db)
                                      (f64.div (get_local $scale) (f64.convert_u/i32 (get_local $width)))
                                      (f64.div (get_local $scale) (f64.convert_u/i32 (get_local $height)))
                                      (get_local $iters))
            )
          )
        )
        
        ;; j = j + 1
        (set_local $j (i32.add (get_local $j) (i32.const 1)))
        (br_if 0 (i32.lt_u (get_local $j) (get_local $h))) ;;continue if j < h
      )
      
      ;; i = i + 1
      (set_local $i (i32.add (get_local $i) (i32.const 1)))
      (br_if 0 (i32.lt_u (get_local $i) (get_local $w))) ;;continue if i < w
    )
    ;; renderChunk end
  )
  
  ;; module end
)
