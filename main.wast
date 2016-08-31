(module
  (memory 128 128)
  (export "memory" memory)
  (export "renderPart" $renderPart)
  
  
  (func $getPixVal (param $da f64) (param $db f64)
                   (param $iters i32) (result f64)
    (local $t f64 $aa f64 $bb f64)
    (local $a f64 $b f64 $k i32)
    (set_local $a (get_local $da))
    (set_local $b (get_local $db))
    (set_local $k (get_local $iters))
    
    (loop $k_loop_stop $k_loop_continue
      (set_local $k (i32.sub (get_local $k) (i32.const 1)))
      
      (br_if
        $k_loop_stop
        (i32.or
          (i32.le_s (get_local $k) (i32.const 0))
          (f64.ge (f64.add (f64.mul (get_local $a) (get_local $a))
                           (f64.mul (get_local $b) (get_local $b)))
                  (f64.const 4))
        )
      )
      
      (set_local $t
        (f64.add
          (f64.sub (f64.mul (get_local $a) (get_local $a))
                   (f64.mul (get_local $b) (get_local $b))
          )
          (get_local $da)
        )
      )
      (set_local $b
        (f64.add
          (f64.mul (f64.const 2) (f64.mul (get_local $a) (get_local $b)))
          (get_local $db)
        )
      )
      (set_local $a (get_local $t))
      
      (br $k_loop_continue)
    )
    
    (set_local $t
      (f64.div
        (f64.convert_u/i32 (get_local $k))
        (f64.convert_u/i32 (get_local $iters))
      )
    )
    
    (set_local $t (f64.mul (get_local $t) (get_local $t))) ;;^2
    (set_local $t (f64.mul (get_local $t) (get_local $t))) ;;^4
    (set_local $t (f64.mul (get_local $t) (get_local $t))) ;;^8
    (set_local $t (f64.mul (get_local $t) (get_local $t))) ;;^16
    (get_local $t)
    ;;getPixVal end
  )
  
  
  (func $getSampledPixVal (param $da f64) (param $db f64)
                          (param $h_pix_size f64) (param $v_pix_size f64)
                          (param $iters i32) (result f64)
    (local $i i32 $j i32)
    (local $sum f64 $o i32 $neg_o i32 $n f64 $dh f64 $dv f64)
    (set_local $sum (f64.const 0))
    (set_local $o (i32.const 2))
    (set_local $neg_o (i32.sub (i32.const 0) (get_local $o)))
    (set_local $n
      (f64.convert_u/i32
        (i32.add (i32.mul (get_local $o) (i32.const 2))
                 (i32.const 1))
      )
    )
    (set_local $dh (f64.div (get_local $h_pix_size) (get_local $n)))
    (set_local $dv (f64.div (get_local $v_pix_size) (get_local $n)))
    
    (set_local $i (get_local $neg_o))
    (loop $i_loop_stop $i_loop_continue
      
      (set_local $j (get_local $neg_o))
      (loop $j_loop_stop $j_loop_continue
        
        (set_local $sum
          (f64.add
            (get_local $sum)
            (call $getPixVal (f64.add (get_local $da)
                                      (f64.mul (get_local $dh)
                                               (f64.convert_s/i32 (get_local $i))))
                             (f64.add (get_local $db)
                                      (f64.mul (get_local $dv)
                                               (f64.convert_s/i32 (get_local $j))))
                             (get_local $iters))
          )
        )
        
        (set_local $j (i32.add (get_local $j) (i32.const 1)))
        (br_if $j_loop_continue (i32.le_s (get_local $j) (get_local $o)))
      )
      
      (set_local $i (i32.add (get_local $i) (i32.const 1)))
      (br_if $i_loop_continue (i32.le_s (get_local $i) (get_local $o)))
    )
    
    (f64.div (get_local $sum) (f64.mul (get_local $n) (get_local $n)))
    ;;getSampledPixVal end
  )
  
  
  (func $renderPart (param $width i32) (param $height i32)
                    (param $xo i32)    (param $yo i32)
                    (param $w i32)     (param $h i32)
    (local $i i32 $j i32)
    (local $da f64 $db f64)
    
    (local $scale f64 $iters i32)
    (set_local $scale (f64.const 2.8))
    (set_local $iters (i32.const 256))
    
    (set_local $i (i32.const 0))
    (loop $i_loop_stop $i_loop_continue
      
      (set_local $j (i32.const 0))
      (loop $j_loop_stop $j_loop_continue
        
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
        
        (i32.store8
          (i32.add
            (i32.mul
              (i32.add
                (get_local $i)
                (i32.mul (get_local $j) (get_local $w))
              )
              (i32.const 4)
            )
            (i32.const 3)
          )
          (i32.trunc_s/f64
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
        
        (set_local $j (i32.add (get_local $j) (i32.const 1)))
        (br_if $j_loop_continue (i32.lt_u (get_local $j) (get_local $h)))
      )
      
      (set_local $i (i32.add (get_local $i) (i32.const 1)))
      (br_if $i_loop_continue (i32.lt_u (get_local $i) (get_local $w)))
    )
    ;;renderPart end
  )
  
  ;;module end
)
