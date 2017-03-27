open Prims
exception Un_extractable 
let uu___is_Un_extractable : Prims.exn -> Prims.bool =
  fun projectee  ->
    match projectee with | Un_extractable  -> true | uu____4 -> false
  
let type_leq :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Extraction_ML_Syntax.mlty ->
      FStar_Extraction_ML_Syntax.mlty -> Prims.bool
  =
  fun g  ->
    fun t1  ->
      fun t2  ->
        FStar_Extraction_ML_Util.type_leq
          (FStar_Extraction_ML_Util.udelta_unfold g) t1 t2
  
let type_leq_c :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Extraction_ML_Syntax.mlexpr Prims.option ->
      FStar_Extraction_ML_Syntax.mlty ->
        FStar_Extraction_ML_Syntax.mlty ->
          (Prims.bool * FStar_Extraction_ML_Syntax.mlexpr Prims.option)
  =
  fun g  ->
    fun t1  ->
      fun t2  ->
        FStar_Extraction_ML_Util.type_leq_c
          (FStar_Extraction_ML_Util.udelta_unfold g) t1 t2
  
let erasableType :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Extraction_ML_Syntax.mlty -> Prims.bool
  =
  fun g  ->
    fun t  ->
      FStar_Extraction_ML_Util.erasableType
        (FStar_Extraction_ML_Util.udelta_unfold g) t
  
let eraseTypeDeep :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Extraction_ML_Syntax.mlty -> FStar_Extraction_ML_Syntax.mlty
  =
  fun g  ->
    fun t  ->
      FStar_Extraction_ML_Util.eraseTypeDeep
        (FStar_Extraction_ML_Util.udelta_unfold g) t
  
let record_fields fs vs =
  FStar_List.map2 (fun f  -> fun e  -> ((f.FStar_Ident.idText), e)) fs vs 
let fail r msg =
  (let _0_482 =
     let _0_481 = FStar_Range.string_of_range r  in
     FStar_Util.format2 "%s: %s\n" _0_481 msg  in
   FStar_All.pipe_left FStar_Util.print_string _0_482);
  failwith msg 
let err_uninst env t uu____105 app =
  match uu____105 with
  | (vars,ty) ->
      let _0_488 =
        let _0_487 = FStar_Syntax_Print.term_to_string t  in
        let _0_486 =
          let _0_483 = FStar_All.pipe_right vars (FStar_List.map Prims.fst)
             in
          FStar_All.pipe_right _0_483 (FStar_String.concat ", ")  in
        let _0_485 =
          FStar_Extraction_ML_Code.string_of_mlty
            env.FStar_Extraction_ML_UEnv.currentModule ty
           in
        let _0_484 = FStar_Syntax_Print.term_to_string app  in
        FStar_Util.format4
          "Variable %s has a polymorphic type (forall %s. %s); expected it to be fully instantiated, but got %s"
          _0_487 _0_486 _0_485 _0_484
         in
      fail t.FStar_Syntax_Syntax.pos _0_488
  
let err_ill_typed_application env t args ty =
  let _0_493 =
    let _0_492 = FStar_Syntax_Print.term_to_string t  in
    let _0_491 =
      let _0_489 =
        FStar_All.pipe_right args
          (FStar_List.map
             (fun uu____164  ->
                match uu____164 with
                | (x,uu____168) -> FStar_Syntax_Print.term_to_string x))
         in
      FStar_All.pipe_right _0_489 (FStar_String.concat " ")  in
    let _0_490 =
      FStar_Extraction_ML_Code.string_of_mlty
        env.FStar_Extraction_ML_UEnv.currentModule ty
       in
    FStar_Util.format3
      "Ill-typed application: application is %s \n remaining args are %s\nml type of head is %s\n"
      _0_492 _0_491 _0_490
     in
  fail t.FStar_Syntax_Syntax.pos _0_493 
let err_value_restriction t =
  let _0_496 =
    let _0_495 = FStar_Syntax_Print.tag_of_term t  in
    let _0_494 = FStar_Syntax_Print.term_to_string t  in
    FStar_Util.format2
      "Refusing to generalize because of the value restriction: (%s) %s"
      _0_495 _0_494
     in
  fail t.FStar_Syntax_Syntax.pos _0_496 
let err_unexpected_eff t f0 f1 =
  let _0_498 =
    let _0_497 = FStar_Syntax_Print.term_to_string t  in
    FStar_Util.format3 "for expression %s, Expected effect %s; got effect %s"
      _0_497 (FStar_Extraction_ML_Util.eff_to_string f0)
      (FStar_Extraction_ML_Util.eff_to_string f1)
     in
  fail t.FStar_Syntax_Syntax.pos _0_498 
let effect_as_etag :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Ident.lident -> FStar_Extraction_ML_Syntax.e_tag
  =
  let cache = FStar_Util.smap_create (Prims.parse_int "20")  in
  let rec delta_norm_eff g l =
    let uu____214 = FStar_Util.smap_try_find cache l.FStar_Ident.str  in
    match uu____214 with
    | Some l -> l
    | None  ->
        let res =
          let uu____218 =
            FStar_TypeChecker_Env.lookup_effect_abbrev
              g.FStar_Extraction_ML_UEnv.tcenv [FStar_Syntax_Syntax.U_zero] l
             in
          match uu____218 with
          | None  -> l
          | Some (uu____224,c) ->
              delta_norm_eff g (FStar_Syntax_Util.comp_effect_name c)
           in
        (FStar_Util.smap_add cache l.FStar_Ident.str res; res)
     in
  fun g  ->
    fun l  ->
      let l = delta_norm_eff g l  in
      if FStar_Ident.lid_equals l FStar_Syntax_Const.effect_PURE_lid
      then FStar_Extraction_ML_Syntax.E_PURE
      else
        if FStar_Ident.lid_equals l FStar_Syntax_Const.effect_GHOST_lid
        then FStar_Extraction_ML_Syntax.E_GHOST
        else FStar_Extraction_ML_Syntax.E_IMPURE
  
let rec is_arity :
  FStar_Extraction_ML_UEnv.env -> FStar_Syntax_Syntax.term -> Prims.bool =
  fun env  ->
    fun t  ->
      let t = FStar_Syntax_Util.unmeta t  in
      let uu____241 = (FStar_Syntax_Subst.compress t).FStar_Syntax_Syntax.n
         in
      match uu____241 with
      | FStar_Syntax_Syntax.Tm_unknown 
        |FStar_Syntax_Syntax.Tm_delayed _
         |FStar_Syntax_Syntax.Tm_ascribed _|FStar_Syntax_Syntax.Tm_meta _ ->
          failwith "Impossible"
      | FStar_Syntax_Syntax.Tm_uvar _
        |FStar_Syntax_Syntax.Tm_constant _
         |FStar_Syntax_Syntax.Tm_name _|FStar_Syntax_Syntax.Tm_bvar _ ->
          false
      | FStar_Syntax_Syntax.Tm_type uu____249 -> true
      | FStar_Syntax_Syntax.Tm_arrow (uu____250,c) ->
          let _0_499 =
            FStar_TypeChecker_Env.result_typ
              env.FStar_Extraction_ML_UEnv.tcenv c
             in
          is_arity env _0_499
      | FStar_Syntax_Syntax.Tm_fvar uu____262 ->
          let t =
            FStar_TypeChecker_Normalize.normalize
              [FStar_TypeChecker_Normalize.AllowUnboundUniverses;
              FStar_TypeChecker_Normalize.EraseUniverses;
              FStar_TypeChecker_Normalize.UnfoldUntil
                FStar_Syntax_Syntax.Delta_constant]
              env.FStar_Extraction_ML_UEnv.tcenv t
             in
          let uu____264 =
            (FStar_Syntax_Subst.compress t).FStar_Syntax_Syntax.n  in
          (match uu____264 with
           | FStar_Syntax_Syntax.Tm_fvar uu____265 -> false
           | uu____266 -> is_arity env t)
      | FStar_Syntax_Syntax.Tm_app uu____267 ->
          let uu____277 = FStar_Syntax_Util.head_and_args t  in
          (match uu____277 with | (head,uu____288) -> is_arity env head)
      | FStar_Syntax_Syntax.Tm_uinst (head,uu____304) -> is_arity env head
      | FStar_Syntax_Syntax.Tm_refine (x,uu____310) ->
          is_arity env x.FStar_Syntax_Syntax.sort
      | FStar_Syntax_Syntax.Tm_abs (_,body,_)|FStar_Syntax_Syntax.Tm_let
        (_,body) -> is_arity env body
      | FStar_Syntax_Syntax.Tm_match (uu____339,branches) ->
          (match branches with
           | (uu____367,uu____368,e)::uu____370 -> is_arity env e
           | uu____406 -> false)
  
let rec is_type_aux :
  FStar_Extraction_ML_UEnv.env -> FStar_Syntax_Syntax.term -> Prims.bool =
  fun env  ->
    fun t  ->
      let t = FStar_Syntax_Subst.compress t  in
      match t.FStar_Syntax_Syntax.n with
      | FStar_Syntax_Syntax.Tm_delayed _|FStar_Syntax_Syntax.Tm_unknown  ->
          failwith
            (let _0_500 = FStar_Syntax_Print.tag_of_term t  in
             FStar_Util.format1 "Impossible: %s" _0_500)
      | FStar_Syntax_Syntax.Tm_constant uu____426 -> false
      | FStar_Syntax_Syntax.Tm_type _
        |FStar_Syntax_Syntax.Tm_refine _|FStar_Syntax_Syntax.Tm_arrow _ ->
          true
      | FStar_Syntax_Syntax.Tm_fvar fv when
          FStar_Syntax_Syntax.fv_eq_lid fv FStar_Syntax_Const.failwith_lid ->
          false
      | FStar_Syntax_Syntax.Tm_fvar fv ->
          let uu____432 =
            FStar_TypeChecker_Env.is_type_constructor
              env.FStar_Extraction_ML_UEnv.tcenv
              (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
             in
          if uu____432
          then true
          else
            (let uu____438 =
               FStar_TypeChecker_Env.lookup_lid
                 env.FStar_Extraction_ML_UEnv.tcenv
                 (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
                in
             match uu____438 with | (uu____445,t) -> is_arity env t)
      | FStar_Syntax_Syntax.Tm_uvar (_,t)
        |FStar_Syntax_Syntax.Tm_bvar
         { FStar_Syntax_Syntax.ppname = _; FStar_Syntax_Syntax.index = _;
           FStar_Syntax_Syntax.sort = t;_}|FStar_Syntax_Syntax.Tm_name
         { FStar_Syntax_Syntax.ppname = _; FStar_Syntax_Syntax.index = _;
           FStar_Syntax_Syntax.sort = t;_}
          -> is_arity env t
      | FStar_Syntax_Syntax.Tm_ascribed (t,uu____466,uu____467) ->
          is_type_aux env t
      | FStar_Syntax_Syntax.Tm_uinst (t,uu____487) -> is_type_aux env t
      | FStar_Syntax_Syntax.Tm_abs (uu____492,body,uu____494) ->
          is_type_aux env body
      | FStar_Syntax_Syntax.Tm_let (uu____517,body) -> is_type_aux env body
      | FStar_Syntax_Syntax.Tm_match (uu____529,branches) ->
          (match branches with
           | (uu____557,uu____558,e)::uu____560 -> is_type_aux env e
           | uu____596 -> failwith "Empty branches")
      | FStar_Syntax_Syntax.Tm_meta (t,uu____609) -> is_type_aux env t
      | FStar_Syntax_Syntax.Tm_app (head,uu____615) -> is_type_aux env head
  
let is_type :
  FStar_Extraction_ML_UEnv.env -> FStar_Syntax_Syntax.term -> Prims.bool =
  fun env  ->
    fun t  ->
      let b = is_type_aux env t  in
      FStar_Extraction_ML_UEnv.debug env
        (fun uu____638  ->
           if b
           then
             let _0_502 = FStar_Syntax_Print.term_to_string t  in
             let _0_501 = FStar_Syntax_Print.tag_of_term t  in
             FStar_Util.print2 "is_type %s (%s)\n" _0_502 _0_501
           else
             (let _0_504 = FStar_Syntax_Print.term_to_string t  in
              let _0_503 = FStar_Syntax_Print.tag_of_term t  in
              FStar_Util.print2 "not a type %s (%s)\n" _0_504 _0_503));
      b
  
let is_type_binder env x =
  is_arity env (Prims.fst x).FStar_Syntax_Syntax.sort 
let is_constructor : FStar_Syntax_Syntax.term -> Prims.bool =
  fun t  ->
    let uu____659 = (FStar_Syntax_Subst.compress t).FStar_Syntax_Syntax.n  in
    match uu____659 with
    | FStar_Syntax_Syntax.Tm_fvar
      { FStar_Syntax_Syntax.fv_name = _; FStar_Syntax_Syntax.fv_delta = _;
        FStar_Syntax_Syntax.fv_qual = Some (FStar_Syntax_Syntax.Data_ctor );_}
      |FStar_Syntax_Syntax.Tm_fvar
      { FStar_Syntax_Syntax.fv_name = _; FStar_Syntax_Syntax.fv_delta = _;
        FStar_Syntax_Syntax.fv_qual = Some (FStar_Syntax_Syntax.Record_ctor
          _);_}
        -> true
    | uu____665 -> false
  
let rec is_fstar_value : FStar_Syntax_Syntax.term -> Prims.bool =
  fun t  ->
    let uu____669 = (FStar_Syntax_Subst.compress t).FStar_Syntax_Syntax.n  in
    match uu____669 with
    | FStar_Syntax_Syntax.Tm_constant _
      |FStar_Syntax_Syntax.Tm_bvar _
       |FStar_Syntax_Syntax.Tm_fvar _|FStar_Syntax_Syntax.Tm_abs _ -> true
    | FStar_Syntax_Syntax.Tm_app (head,args) ->
        let uu____690 = is_constructor head  in
        if uu____690
        then
          FStar_All.pipe_right args
            (FStar_List.for_all
               (fun uu____698  ->
                  match uu____698 with | (te,uu____702) -> is_fstar_value te))
        else false
    | FStar_Syntax_Syntax.Tm_meta (t,_)|FStar_Syntax_Syntax.Tm_ascribed
      (t,_,_) -> is_fstar_value t
    | uu____723 -> false
  
let rec is_ml_value : FStar_Extraction_ML_Syntax.mlexpr -> Prims.bool =
  fun e  ->
    match e.FStar_Extraction_ML_Syntax.expr with
    | FStar_Extraction_ML_Syntax.MLE_Const _
      |FStar_Extraction_ML_Syntax.MLE_Var _
       |FStar_Extraction_ML_Syntax.MLE_Name _
        |FStar_Extraction_ML_Syntax.MLE_Fun _ -> true
    | FStar_Extraction_ML_Syntax.MLE_CTor (_,exps)
      |FStar_Extraction_ML_Syntax.MLE_Tuple exps ->
        FStar_Util.for_all is_ml_value exps
    | FStar_Extraction_ML_Syntax.MLE_Record (uu____736,fields) ->
        FStar_Util.for_all
          (fun uu____748  ->
             match uu____748 with | (uu____751,e) -> is_ml_value e) fields
    | uu____753 -> false
  
let normalize_abs : FStar_Syntax_Syntax.term -> FStar_Syntax_Syntax.term =
  fun t0  ->
    let rec aux bs t copt =
      let t = FStar_Syntax_Subst.compress t  in
      match t.FStar_Syntax_Syntax.n with
      | FStar_Syntax_Syntax.Tm_abs (bs',body,copt) ->
          aux (FStar_List.append bs bs') body copt
      | uu____813 ->
          let e' = FStar_Syntax_Util.unascribe t  in
          let uu____815 = FStar_Syntax_Util.is_fun e'  in
          if uu____815
          then aux bs e' copt
          else FStar_Syntax_Util.abs bs e' copt
       in
    aux [] t0 None
  
let unit_binder : FStar_Syntax_Syntax.binder =
  let _0_505 =
    FStar_Syntax_Syntax.new_bv None FStar_TypeChecker_Common.t_unit  in
  FStar_All.pipe_left FStar_Syntax_Syntax.mk_binder _0_505 
let check_pats_for_ite :
  (FStar_Syntax_Syntax.pat * FStar_Syntax_Syntax.term Prims.option *
    FStar_Syntax_Syntax.term) Prims.list ->
    (Prims.bool * FStar_Syntax_Syntax.term Prims.option *
      FStar_Syntax_Syntax.term Prims.option)
  =
  fun l  ->
    let def = (false, None, None)  in
    if (FStar_List.length l) <> (Prims.parse_int "2")
    then def
    else
      (let uu____867 = FStar_List.hd l  in
       match uu____867 with
       | (p1,w1,e1) ->
           let uu____886 = FStar_List.hd (FStar_List.tl l)  in
           (match uu____886 with
            | (p2,w2,e2) ->
                (match (w1, w2, (p1.FStar_Syntax_Syntax.v),
                         (p2.FStar_Syntax_Syntax.v))
                 with
                 | (None ,None ,FStar_Syntax_Syntax.Pat_constant
                    (FStar_Const.Const_bool (true
                    )),FStar_Syntax_Syntax.Pat_constant
                    (FStar_Const.Const_bool (false ))) ->
                     (true, (Some e1), (Some e2))
                 | (None ,None ,FStar_Syntax_Syntax.Pat_constant
                    (FStar_Const.Const_bool (false
                    )),FStar_Syntax_Syntax.Pat_constant
                    (FStar_Const.Const_bool (true ))) ->
                     (true, (Some e2), (Some e1))
                 | uu____924 -> def)))
  
let instantiate :
  FStar_Extraction_ML_Syntax.mltyscheme ->
    FStar_Extraction_ML_Syntax.mlty Prims.list ->
      FStar_Extraction_ML_Syntax.mlty
  = fun s  -> fun args  -> FStar_Extraction_ML_Util.subst s args 
let erasable :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Extraction_ML_Syntax.e_tag ->
      FStar_Extraction_ML_Syntax.mlty -> Prims.bool
  =
  fun g  ->
    fun f  ->
      fun t  ->
        (f = FStar_Extraction_ML_Syntax.E_GHOST) ||
          ((f = FStar_Extraction_ML_Syntax.E_PURE) && (erasableType g t))
  
let erase :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Extraction_ML_Syntax.mlexpr ->
      FStar_Extraction_ML_Syntax.mlty ->
        FStar_Extraction_ML_Syntax.e_tag ->
          (FStar_Extraction_ML_Syntax.mlexpr *
            FStar_Extraction_ML_Syntax.e_tag *
            FStar_Extraction_ML_Syntax.mlty)
  =
  fun g  ->
    fun e  ->
      fun ty  ->
        fun f  ->
          let e =
            let uu____967 = erasable g f ty  in
            if uu____967
            then
              let uu____968 =
                type_leq g ty FStar_Extraction_ML_Syntax.ml_unit_ty  in
              (if uu____968
               then FStar_Extraction_ML_Syntax.ml_unit
               else
                 FStar_All.pipe_left (FStar_Extraction_ML_Syntax.with_ty ty)
                   (FStar_Extraction_ML_Syntax.MLE_Coerce
                      (FStar_Extraction_ML_Syntax.ml_unit,
                        FStar_Extraction_ML_Syntax.ml_unit_ty, ty)))
            else e  in
          (e, f, ty)
  
let maybe_coerce :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Extraction_ML_Syntax.mlexpr ->
      FStar_Extraction_ML_Syntax.mlty ->
        FStar_Extraction_ML_Syntax.mlty -> FStar_Extraction_ML_Syntax.mlexpr
  =
  fun g  ->
    fun e  ->
      fun ty  ->
        fun expect  ->
          let ty = eraseTypeDeep g ty  in
          let uu____984 = (type_leq_c g (Some e) ty) expect  in
          match uu____984 with
          | (true ,Some e') -> e'
          | uu____990 ->
              (FStar_Extraction_ML_UEnv.debug g
                 (fun uu____995  ->
                    let _0_508 =
                      FStar_Extraction_ML_Code.string_of_mlexpr
                        g.FStar_Extraction_ML_UEnv.currentModule e
                       in
                    let _0_507 =
                      FStar_Extraction_ML_Code.string_of_mlty
                        g.FStar_Extraction_ML_UEnv.currentModule ty
                       in
                    let _0_506 =
                      FStar_Extraction_ML_Code.string_of_mlty
                        g.FStar_Extraction_ML_UEnv.currentModule expect
                       in
                    FStar_Util.print3
                      "\n (*needed to coerce expression \n %s \n of type \n %s \n to type \n %s *) \n"
                      _0_508 _0_507 _0_506);
               FStar_All.pipe_left
                 (FStar_Extraction_ML_Syntax.with_ty expect)
                 (FStar_Extraction_ML_Syntax.MLE_Coerce (e, ty, expect)))
  
let bv_as_mlty :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.bv -> FStar_Extraction_ML_Syntax.mlty
  =
  fun g  ->
    fun bv  ->
      let uu____1002 = FStar_Extraction_ML_UEnv.lookup_bv g bv  in
      match uu____1002 with
      | FStar_Util.Inl (uu____1003,t) -> t
      | uu____1010 -> FStar_Extraction_ML_Syntax.MLTY_Top
  
let rec term_as_mlty :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.term -> FStar_Extraction_ML_Syntax.mlty
  =
  fun g  ->
    fun t0  ->
      let t =
        FStar_TypeChecker_Normalize.normalize
          [FStar_TypeChecker_Normalize.Beta;
          FStar_TypeChecker_Normalize.Eager_unfolding;
          FStar_TypeChecker_Normalize.Iota;
          FStar_TypeChecker_Normalize.Zeta;
          FStar_TypeChecker_Normalize.EraseUniverses;
          FStar_TypeChecker_Normalize.AllowUnboundUniverses]
          g.FStar_Extraction_ML_UEnv.tcenv t0
         in
      let mlt = term_as_mlty' g t  in
      let uu____1044 =
        (fun t  ->
           match t with
           | FStar_Extraction_ML_Syntax.MLTY_Top  -> true
           | FStar_Extraction_ML_Syntax.MLTY_Named uu____1046 ->
               let uu____1050 = FStar_Extraction_ML_Util.udelta_unfold g t
                  in
               (match uu____1050 with
                | None  -> false
                | Some t ->
                    (let rec is_top_ty t =
                       match t with
                       | FStar_Extraction_ML_Syntax.MLTY_Top  -> true
                       | FStar_Extraction_ML_Syntax.MLTY_Named uu____1057 ->
                           let uu____1061 =
                             FStar_Extraction_ML_Util.udelta_unfold g t  in
                           (match uu____1061 with
                            | None  -> false
                            | Some t -> is_top_ty t)
                       | uu____1064 -> false  in
                     is_top_ty) t)
           | uu____1065 -> false) mlt
         in
      if uu____1044
      then
        let t =
          FStar_TypeChecker_Normalize.normalize
            [FStar_TypeChecker_Normalize.Beta;
            FStar_TypeChecker_Normalize.Eager_unfolding;
            FStar_TypeChecker_Normalize.UnfoldUntil
              FStar_Syntax_Syntax.Delta_constant;
            FStar_TypeChecker_Normalize.Iota;
            FStar_TypeChecker_Normalize.Zeta;
            FStar_TypeChecker_Normalize.EraseUniverses;
            FStar_TypeChecker_Normalize.AllowUnboundUniverses]
            g.FStar_Extraction_ML_UEnv.tcenv t0
           in
        term_as_mlty' g t
      else mlt

and term_as_mlty' :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.term -> FStar_Extraction_ML_Syntax.mlty
  =
  fun env  ->
    fun t  ->
      let t = FStar_Syntax_Subst.compress t  in
      match t.FStar_Syntax_Syntax.n with
      | FStar_Syntax_Syntax.Tm_bvar _
        |FStar_Syntax_Syntax.Tm_delayed _|FStar_Syntax_Syntax.Tm_unknown  ->
          failwith
            (let _0_509 = FStar_Syntax_Print.term_to_string t  in
             FStar_Util.format1 "Impossible: Unexpected term %s" _0_509)
      | FStar_Syntax_Syntax.Tm_constant uu____1073 ->
          FStar_Extraction_ML_UEnv.unknownType
      | FStar_Syntax_Syntax.Tm_uvar uu____1074 ->
          FStar_Extraction_ML_UEnv.unknownType
      | FStar_Syntax_Syntax.Tm_meta (t,_)
        |FStar_Syntax_Syntax.Tm_refine
         ({ FStar_Syntax_Syntax.ppname = _; FStar_Syntax_Syntax.index = _;
            FStar_Syntax_Syntax.sort = t;_},_)
         |FStar_Syntax_Syntax.Tm_uinst (t,_)|FStar_Syntax_Syntax.Tm_ascribed
          (t,_,_) -> term_as_mlty' env t
      | FStar_Syntax_Syntax.Tm_name bv -> bv_as_mlty env bv
      | FStar_Syntax_Syntax.Tm_fvar fv -> fv_app_as_mlty env fv []
      | FStar_Syntax_Syntax.Tm_arrow (bs,c) ->
          let uu____1132 = FStar_Syntax_Subst.open_comp bs c  in
          (match uu____1132 with
           | (bs,c) ->
               let uu____1137 = binders_as_ml_binders env bs  in
               (match uu____1137 with
                | (mlbs,env) ->
                    let t_ret =
                      let eff =
                        FStar_TypeChecker_Env.norm_eff_name
                          env.FStar_Extraction_ML_UEnv.tcenv
                          (FStar_Syntax_Util.comp_effect_name c)
                         in
                      let ed =
                        FStar_TypeChecker_Env.get_effect_decl
                          env.FStar_Extraction_ML_UEnv.tcenv eff
                         in
                      let uu____1154 =
                        FStar_All.pipe_right
                          ed.FStar_Syntax_Syntax.qualifiers
                          (FStar_List.contains FStar_Syntax_Syntax.Reifiable)
                         in
                      if uu____1154
                      then
                        let t =
                          let _0_510 =
                            FStar_TypeChecker_Env.lcomp_of_comp
                              env.FStar_Extraction_ML_UEnv.tcenv c
                             in
                          FStar_TypeChecker_Util.reify_comp
                            env.FStar_Extraction_ML_UEnv.tcenv _0_510
                           in
                        let res = term_as_mlty' env t  in res
                      else
                        (let _0_511 =
                           FStar_TypeChecker_Env.result_typ
                             env.FStar_Extraction_ML_UEnv.tcenv c
                            in
                         term_as_mlty' env _0_511)
                       in
                    let erase =
                      effect_as_etag env
                        (FStar_Syntax_Util.comp_effect_name c)
                       in
                    let uu____1160 =
                      FStar_List.fold_right
                        (fun uu____1167  ->
                           fun uu____1168  ->
                             match (uu____1167, uu____1168) with
                             | ((uu____1179,t),(tag,t')) ->
                                 (FStar_Extraction_ML_Syntax.E_PURE,
                                   (FStar_Extraction_ML_Syntax.MLTY_Fun
                                      (t, tag, t')))) mlbs (erase, t_ret)
                       in
                    (match uu____1160 with | (uu____1187,t) -> t)))
      | FStar_Syntax_Syntax.Tm_app (head,args) ->
          let res =
            let uu____1206 =
              (FStar_Syntax_Util.un_uinst head).FStar_Syntax_Syntax.n  in
            match uu____1206 with
            | FStar_Syntax_Syntax.Tm_name bv -> bv_as_mlty env bv
            | FStar_Syntax_Syntax.Tm_fvar fv -> fv_app_as_mlty env fv args
            | FStar_Syntax_Syntax.Tm_app (head,args') ->
                let _0_512 =
                  FStar_Syntax_Syntax.mk
                    (FStar_Syntax_Syntax.Tm_app
                       (head, (FStar_List.append args' args))) None
                    t.FStar_Syntax_Syntax.pos
                   in
                term_as_mlty' env _0_512
            | uu____1244 -> FStar_Extraction_ML_UEnv.unknownType  in
          res
      | FStar_Syntax_Syntax.Tm_abs (bs,ty,uu____1247) ->
          let uu____1270 = FStar_Syntax_Subst.open_term bs ty  in
          (match uu____1270 with
           | (bs,ty) ->
               let uu____1275 = binders_as_ml_binders env bs  in
               (match uu____1275 with | (bts,env) -> term_as_mlty' env ty))
      | FStar_Syntax_Syntax.Tm_type _
        |FStar_Syntax_Syntax.Tm_let _|FStar_Syntax_Syntax.Tm_match _ ->
          FStar_Extraction_ML_UEnv.unknownType

and arg_as_mlty :
  FStar_Extraction_ML_UEnv.env ->
    (FStar_Syntax_Syntax.term * FStar_Syntax_Syntax.aqual) ->
      FStar_Extraction_ML_Syntax.mlty
  =
  fun g  ->
    fun uu____1293  ->
      match uu____1293 with
      | (a,uu____1297) ->
          let uu____1298 = is_type g a  in
          if uu____1298
          then term_as_mlty' g a
          else FStar_Extraction_ML_UEnv.erasedContent

and fv_app_as_mlty :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.fv ->
      FStar_Syntax_Syntax.args -> FStar_Extraction_ML_Syntax.mlty
  =
  fun g  ->
    fun fv  ->
      fun args  ->
        let uu____1303 =
          FStar_TypeChecker_Util.arrow_formals
            g.FStar_Extraction_ML_UEnv.tcenv
            (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.ty
           in
        match uu____1303 with
        | (formals,t) ->
            let mlargs = FStar_List.map (arg_as_mlty g) args  in
            let mlargs =
              let n_args = FStar_List.length args  in
              if (FStar_List.length formals) > n_args
              then
                let uu____1332 = FStar_Util.first_N n_args formals  in
                match uu____1332 with
                | (uu____1346,rest) ->
                    let _0_513 =
                      FStar_List.map
                        (fun uu____1362  ->
                           FStar_Extraction_ML_UEnv.erasedContent) rest
                       in
                    FStar_List.append mlargs _0_513
              else mlargs  in
            let nm =
              let uu____1367 =
                FStar_Extraction_ML_UEnv.maybe_mangle_type_projector g fv  in
              match uu____1367 with
              | Some p -> p
              | None  ->
                  FStar_Extraction_ML_Syntax.mlpath_of_lident
                    (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
               in
            FStar_Extraction_ML_Syntax.MLTY_Named (mlargs, nm)

and binders_as_ml_binders :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.binders ->
      ((FStar_Extraction_ML_Syntax.mlident * FStar_Extraction_ML_Syntax.mlty)
        Prims.list * FStar_Extraction_ML_UEnv.env)
  =
  fun g  ->
    fun bs  ->
      let uu____1382 =
        FStar_All.pipe_right bs
          (FStar_List.fold_left
             (fun uu____1406  ->
                fun b  ->
                  match uu____1406 with
                  | (ml_bs,env) ->
                      let uu____1436 = is_type_binder g b  in
                      if uu____1436
                      then
                        let b = Prims.fst b  in
                        let env =
                          FStar_Extraction_ML_UEnv.extend_ty env b
                            (Some FStar_Extraction_ML_Syntax.MLTY_Top)
                           in
                        let ml_b =
                          let _0_514 =
                            FStar_Extraction_ML_UEnv.bv_as_ml_termvar b  in
                          (_0_514, FStar_Extraction_ML_Syntax.ml_unit_ty)  in
                        ((ml_b :: ml_bs), env)
                      else
                        (let b = Prims.fst b  in
                         let t = term_as_mlty env b.FStar_Syntax_Syntax.sort
                            in
                         let env =
                           FStar_Extraction_ML_UEnv.extend_bv env b ([], t)
                             false false false
                            in
                         let ml_b =
                           let _0_515 =
                             FStar_Extraction_ML_UEnv.bv_as_ml_termvar b  in
                           (_0_515, t)  in
                         ((ml_b :: ml_bs), env))) ([], g))
         in
      match uu____1382 with | (ml_bs,env) -> ((FStar_List.rev ml_bs), env)

let mk_MLE_Seq :
  FStar_Extraction_ML_Syntax.mlexpr ->
    FStar_Extraction_ML_Syntax.mlexpr -> FStar_Extraction_ML_Syntax.mlexpr'
  =
  fun e1  ->
    fun e2  ->
      match ((e1.FStar_Extraction_ML_Syntax.expr),
              (e2.FStar_Extraction_ML_Syntax.expr))
      with
      | (FStar_Extraction_ML_Syntax.MLE_Seq
         es1,FStar_Extraction_ML_Syntax.MLE_Seq es2) ->
          FStar_Extraction_ML_Syntax.MLE_Seq (FStar_List.append es1 es2)
      | (FStar_Extraction_ML_Syntax.MLE_Seq es1,uu____1529) ->
          FStar_Extraction_ML_Syntax.MLE_Seq (FStar_List.append es1 [e2])
      | (uu____1531,FStar_Extraction_ML_Syntax.MLE_Seq es2) ->
          FStar_Extraction_ML_Syntax.MLE_Seq (e1 :: es2)
      | uu____1534 -> FStar_Extraction_ML_Syntax.MLE_Seq [e1; e2]
  
let mk_MLE_Let :
  Prims.bool ->
    FStar_Extraction_ML_Syntax.mlletbinding ->
      FStar_Extraction_ML_Syntax.mlexpr -> FStar_Extraction_ML_Syntax.mlexpr'
  =
  fun top_level  ->
    fun lbs  ->
      fun body  ->
        match lbs with
        | (FStar_Extraction_ML_Syntax.NonRec ,quals,lb::[]) when
            Prims.op_Negation top_level ->
            (match lb.FStar_Extraction_ML_Syntax.mllb_tysc with
             | Some ([],t) when t = FStar_Extraction_ML_Syntax.ml_unit_ty ->
                 if
                   body.FStar_Extraction_ML_Syntax.expr =
                     FStar_Extraction_ML_Syntax.ml_unit.FStar_Extraction_ML_Syntax.expr
                 then
                   (lb.FStar_Extraction_ML_Syntax.mllb_def).FStar_Extraction_ML_Syntax.expr
                 else
                   (match body.FStar_Extraction_ML_Syntax.expr with
                    | FStar_Extraction_ML_Syntax.MLE_Var x when
                        x = lb.FStar_Extraction_ML_Syntax.mllb_name ->
                        (lb.FStar_Extraction_ML_Syntax.mllb_def).FStar_Extraction_ML_Syntax.expr
                    | uu____1556 when
                        (lb.FStar_Extraction_ML_Syntax.mllb_def).FStar_Extraction_ML_Syntax.expr
                          =
                          FStar_Extraction_ML_Syntax.ml_unit.FStar_Extraction_ML_Syntax.expr
                        -> body.FStar_Extraction_ML_Syntax.expr
                    | uu____1557 ->
                        mk_MLE_Seq lb.FStar_Extraction_ML_Syntax.mllb_def
                          body)
             | uu____1558 -> FStar_Extraction_ML_Syntax.MLE_Let (lbs, body))
        | uu____1560 -> FStar_Extraction_ML_Syntax.MLE_Let (lbs, body)
  
let resugar_pat :
  FStar_Syntax_Syntax.fv_qual Prims.option ->
    FStar_Extraction_ML_Syntax.mlpattern ->
      FStar_Extraction_ML_Syntax.mlpattern
  =
  fun q  ->
    fun p  ->
      match p with
      | FStar_Extraction_ML_Syntax.MLP_CTor (d,pats) ->
          (match FStar_Extraction_ML_Util.is_xtuple d with
           | Some n -> FStar_Extraction_ML_Syntax.MLP_Tuple pats
           | uu____1574 ->
               (match q with
                | Some (FStar_Syntax_Syntax.Record_ctor (ty,fns)) ->
                    let path =
                      FStar_List.map FStar_Ident.text_of_id ty.FStar_Ident.ns
                       in
                    let fs = record_fields fns pats  in
                    FStar_Extraction_ML_Syntax.MLP_Record (path, fs)
                | uu____1590 -> p))
      | uu____1592 -> p
  
let rec extract_one_pat :
  Prims.bool ->
    Prims.bool ->
      FStar_Extraction_ML_UEnv.env ->
        FStar_Syntax_Syntax.pat ->
          FStar_Extraction_ML_Syntax.mlty Prims.option ->
            (FStar_Extraction_ML_UEnv.env *
              (FStar_Extraction_ML_Syntax.mlpattern *
              FStar_Extraction_ML_Syntax.mlexpr Prims.list) Prims.option *
              Prims.bool)
  =
  fun disjunctive_pat  ->
    fun imp  ->
      fun g  ->
        fun p  ->
          fun expected_topt  ->
            let ok t =
              match expected_topt with
              | None  -> true
              | Some t' ->
                  let ok = type_leq g t t'  in
                  (if Prims.op_Negation ok
                   then
                     FStar_Extraction_ML_UEnv.debug g
                       (fun uu____1631  ->
                          let _0_517 =
                            FStar_Extraction_ML_Code.string_of_mlty
                              g.FStar_Extraction_ML_UEnv.currentModule t'
                             in
                          let _0_516 =
                            FStar_Extraction_ML_Code.string_of_mlty
                              g.FStar_Extraction_ML_UEnv.currentModule t
                             in
                          FStar_Util.print2
                            "Expected pattern type %s; got pattern type %s\n"
                            _0_517 _0_516)
                   else ();
                   ok)
               in
            match p.FStar_Syntax_Syntax.v with
            | FStar_Syntax_Syntax.Pat_disj uu____1640 ->
                failwith "Impossible: Nested disjunctive pattern"
            | FStar_Syntax_Syntax.Pat_constant (FStar_Const.Const_int
                (c,None )) ->
                let i = FStar_Const.Const_int (c, None)  in
                let x = FStar_Extraction_ML_Syntax.gensym ()  in
                let when_clause =
                  let _0_525 =
                    FStar_Extraction_ML_Syntax.MLE_App
                      (let _0_524 =
                         let _0_523 =
                           FStar_All.pipe_left
                             (FStar_Extraction_ML_Syntax.with_ty
                                FStar_Extraction_ML_Syntax.ml_int_ty)
                             (FStar_Extraction_ML_Syntax.MLE_Var x)
                            in
                         let _0_522 =
                           let _0_521 =
                             let _0_520 =
                               let _0_519 =
                                 FStar_Extraction_ML_Util.mlconst_of_const'
                                   p.FStar_Syntax_Syntax.p i
                                  in
                               FStar_All.pipe_left
                                 (fun _0_518  ->
                                    FStar_Extraction_ML_Syntax.MLE_Const
                                      _0_518) _0_519
                                in
                             FStar_All.pipe_left
                               (FStar_Extraction_ML_Syntax.with_ty
                                  FStar_Extraction_ML_Syntax.ml_int_ty)
                               _0_520
                              in
                           [_0_521]  in
                         _0_523 :: _0_522  in
                       (FStar_Extraction_ML_Util.prims_op_equality, _0_524))
                     in
                  FStar_All.pipe_left
                    (FStar_Extraction_ML_Syntax.with_ty
                       FStar_Extraction_ML_Syntax.ml_bool_ty) _0_525
                   in
                let _0_526 = ok FStar_Extraction_ML_Syntax.ml_int_ty  in
                (g,
                  (Some
                     ((FStar_Extraction_ML_Syntax.MLP_Var x), [when_clause])),
                  _0_526)
            | FStar_Syntax_Syntax.Pat_constant s ->
                let t =
                  FStar_TypeChecker_TcTerm.tc_constant FStar_Range.dummyRange
                    s
                   in
                let mlty = term_as_mlty g t  in
                let _0_529 =
                  Some
                    (let _0_527 =
                       FStar_Extraction_ML_Syntax.MLP_Const
                         (FStar_Extraction_ML_Util.mlconst_of_const'
                            p.FStar_Syntax_Syntax.p s)
                        in
                     (_0_527, []))
                   in
                let _0_528 = ok mlty  in (g, _0_529, _0_528)
            | FStar_Syntax_Syntax.Pat_var x ->
                let mlty = term_as_mlty g x.FStar_Syntax_Syntax.sort  in
                let g =
                  FStar_Extraction_ML_UEnv.extend_bv g x ([], mlty) false
                    false imp
                   in
                let _0_532 =
                  if imp
                  then None
                  else
                    Some
                      ((let _0_530 =
                          FStar_Extraction_ML_Syntax.MLP_Var
                            (FStar_Extraction_ML_Syntax.bv_as_mlident x)
                           in
                        (_0_530, [])))
                   in
                let _0_531 = ok mlty  in (g, _0_532, _0_531)
            | FStar_Syntax_Syntax.Pat_wild x when disjunctive_pat ->
                (g, (Some (FStar_Extraction_ML_Syntax.MLP_Wild, [])), true)
            | FStar_Syntax_Syntax.Pat_wild x ->
                let mlty = term_as_mlty g x.FStar_Syntax_Syntax.sort  in
                let g =
                  FStar_Extraction_ML_UEnv.extend_bv g x ([], mlty) false
                    false imp
                   in
                let _0_535 =
                  if imp
                  then None
                  else
                    Some
                      ((let _0_533 =
                          FStar_Extraction_ML_Syntax.MLP_Var
                            (FStar_Extraction_ML_Syntax.bv_as_mlident x)
                           in
                        (_0_533, [])))
                   in
                let _0_534 = ok mlty  in (g, _0_535, _0_534)
            | FStar_Syntax_Syntax.Pat_dot_term uu____1734 -> (g, None, true)
            | FStar_Syntax_Syntax.Pat_cons (f,pats) ->
                let uu____1758 =
                  let uu____1761 = FStar_Extraction_ML_UEnv.lookup_fv g f  in
                  match uu____1761 with
                  | FStar_Util.Inr
                      ({
                         FStar_Extraction_ML_Syntax.expr =
                           FStar_Extraction_ML_Syntax.MLE_Name n;
                         FStar_Extraction_ML_Syntax.mlty = uu____1765;
                         FStar_Extraction_ML_Syntax.loc = uu____1766;_},ttys,uu____1768)
                      -> (n, ttys)
                  | uu____1774 -> failwith "Expected a constructor"  in
                (match uu____1758 with
                 | (d,tys) ->
                     let nTyVars = FStar_List.length (Prims.fst tys)  in
                     let uu____1788 = FStar_Util.first_N nTyVars pats  in
                     (match uu____1788 with
                      | (tysVarPats,restPats) ->
                          let f_ty_opt =
                            try
                              let mlty_args =
                                FStar_All.pipe_right tysVarPats
                                  (FStar_List.map
                                     (fun uu____1862  ->
                                        match uu____1862 with
                                        | (p,uu____1868) ->
                                            (match p.FStar_Syntax_Syntax.v
                                             with
                                             | FStar_Syntax_Syntax.Pat_dot_term
                                                 (uu____1873,t) ->
                                                 term_as_mlty g t
                                             | uu____1879 ->
                                                 (FStar_Extraction_ML_UEnv.debug
                                                    g
                                                    (fun uu____1881  ->
                                                       let _0_536 =
                                                         FStar_Syntax_Print.pat_to_string
                                                           p
                                                          in
                                                       FStar_Util.print1
                                                         "Pattern %s is not extractable"
                                                         _0_536);
                                                  Prims.raise Un_extractable))))
                                 in
                              let f_ty =
                                FStar_Extraction_ML_Util.subst tys mlty_args
                                 in
                              Some
                                (FStar_Extraction_ML_Util.uncurry_mlty_fun
                                   f_ty)
                            with | Un_extractable  -> None  in
                          let uu____1894 =
                            FStar_Util.fold_map
                              (fun g  ->
                                 fun uu____1909  ->
                                   match uu____1909 with
                                   | (p,imp) ->
                                       let uu____1920 =
                                         extract_one_pat disjunctive_pat true
                                           g p None
                                          in
                                       (match uu____1920 with
                                        | (g,p,uu____1936) -> (g, p))) g
                              tysVarPats
                             in
                          (match uu____1894 with
                           | (g,tyMLPats) ->
                               let uu____1968 =
                                 FStar_Util.fold_map
                                   (fun uu____1994  ->
                                      fun uu____1995  ->
                                        match (uu____1994, uu____1995) with
                                        | ((g,f_ty_opt),(p,imp)) ->
                                            let uu____2044 =
                                              match f_ty_opt with
                                              | Some (hd::rest,res) ->
                                                  ((Some (rest, res)),
                                                    (Some hd))
                                              | uu____2076 -> (None, None)
                                               in
                                            (match uu____2044 with
                                             | (f_ty_opt,expected_ty) ->
                                                 let uu____2113 =
                                                   extract_one_pat
                                                     disjunctive_pat false g
                                                     p expected_ty
                                                    in
                                                 (match uu____2113 with
                                                  | (g,p,uu____2135) ->
                                                      ((g, f_ty_opt), p))))
                                   (g, f_ty_opt) restPats
                                  in
                               (match uu____1968 with
                                | ((g,f_ty_opt),restMLPats) ->
                                    let uu____2196 =
                                      let _0_537 =
                                        FStar_All.pipe_right
                                          (FStar_List.append tyMLPats
                                             restMLPats)
                                          (FStar_List.collect
                                             (fun uu___134_2231  ->
                                                match uu___134_2231 with
                                                | Some x -> [x]
                                                | uu____2253 -> []))
                                         in
                                      FStar_All.pipe_right _0_537
                                        FStar_List.split
                                       in
                                    (match uu____2196 with
                                     | (mlPats,when_clauses) ->
                                         let pat_ty_compat =
                                           match f_ty_opt with
                                           | Some ([],t) -> ok t
                                           | uu____2283 -> false  in
                                         let _0_540 =
                                           Some
                                             (let _0_539 =
                                                resugar_pat
                                                  f.FStar_Syntax_Syntax.fv_qual
                                                  (FStar_Extraction_ML_Syntax.MLP_CTor
                                                     (d, mlPats))
                                                 in
                                              let _0_538 =
                                                FStar_All.pipe_right
                                                  when_clauses
                                                  FStar_List.flatten
                                                 in
                                              (_0_539, _0_538))
                                            in
                                         (g, _0_540, pat_ty_compat))))))
  
let extract_pat :
  FStar_Extraction_ML_UEnv.env ->
    (FStar_Syntax_Syntax.pat',FStar_Syntax_Syntax.term')
      FStar_Syntax_Syntax.withinfo_t ->
      FStar_Extraction_ML_Syntax.mlty ->
        (FStar_Extraction_ML_UEnv.env * (FStar_Extraction_ML_Syntax.mlpattern
          * FStar_Extraction_ML_Syntax.mlexpr Prims.option) Prims.list *
          Prims.bool)
  =
  fun g  ->
    fun p  ->
      fun expected_t  ->
        let extract_one_pat disj g p expected_t =
          let uu____2348 = extract_one_pat disj false g p expected_t  in
          match uu____2348 with
          | (g,Some (x,v),b) -> (g, (x, v), b)
          | uu____2379 -> failwith "Impossible: Unable to translate pattern"
           in
        let mk_when_clause whens =
          match whens with
          | [] -> None
          | hd::tl ->
              Some
                (FStar_List.fold_left FStar_Extraction_ML_Util.conjoin hd tl)
           in
        match p.FStar_Syntax_Syntax.v with
        | FStar_Syntax_Syntax.Pat_disj [] ->
            failwith "Impossible: Empty disjunctive pattern"
        | FStar_Syntax_Syntax.Pat_disj (p::pats) ->
            let uu____2429 = extract_one_pat true g p (Some expected_t)  in
            (match uu____2429 with
             | (g,p,b) ->
                 let uu____2452 =
                   FStar_Util.fold_map
                     (fun b  ->
                        fun p  ->
                          let uu____2464 =
                            extract_one_pat true g p (Some expected_t)  in
                          match uu____2464 with
                          | (uu____2476,p,b') -> ((b && b'), p)) b pats
                    in
                 (match uu____2452 with
                  | (b,ps) ->
                      let ps = p :: ps  in
                      let uu____2513 =
                        FStar_All.pipe_right ps
                          (FStar_List.partition
                             (fun uu___135_2541  ->
                                match uu___135_2541 with
                                | (uu____2545,uu____2546::uu____2547) -> true
                                | uu____2550 -> false))
                         in
                      (match uu____2513 with
                       | (ps_when,rest) ->
                           let ps =
                             FStar_All.pipe_right ps_when
                               (FStar_List.map
                                  (fun uu____2598  ->
                                     match uu____2598 with
                                     | (x,whens) ->
                                         let _0_541 = mk_when_clause whens
                                            in
                                         (x, _0_541)))
                              in
                           let res =
                             match rest with
                             | [] -> (g, ps, b)
                             | rest ->
                                 let _0_544 =
                                   let _0_543 =
                                     let _0_542 =
                                       FStar_Extraction_ML_Syntax.MLP_Branch
                                         (FStar_List.map Prims.fst rest)
                                        in
                                     (_0_542, None)  in
                                   _0_543 :: ps  in
                                 (g, _0_544, b)
                              in
                           res)))
        | uu____2649 ->
            let uu____2650 = extract_one_pat false g p (Some expected_t)  in
            (match uu____2650 with
             | (g,(p,whens),b) ->
                 let when_clause = mk_when_clause whens  in
                 (g, [(p, when_clause)], b))
  
let maybe_eta_data_and_project_record :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.fv_qual Prims.option ->
      FStar_Extraction_ML_Syntax.mlty ->
        FStar_Extraction_ML_Syntax.mlexpr ->
          FStar_Extraction_ML_Syntax.mlexpr
  =
  fun g  ->
    fun qual  ->
      fun residualType  ->
        fun mlAppExpr  ->
          let rec eta_args more_args t =
            match t with
            | FStar_Extraction_ML_Syntax.MLTY_Fun (t0,uu____2732,t1) ->
                let x = FStar_Extraction_ML_Syntax.gensym ()  in
                let _0_547 =
                  let _0_546 =
                    let _0_545 =
                      FStar_All.pipe_left
                        (FStar_Extraction_ML_Syntax.with_ty t0)
                        (FStar_Extraction_ML_Syntax.MLE_Var x)
                       in
                    ((x, t0), _0_545)  in
                  _0_546 :: more_args  in
                eta_args _0_547 t1
            | FStar_Extraction_ML_Syntax.MLTY_Named (uu____2741,uu____2742)
                -> ((FStar_List.rev more_args), t)
            | uu____2754 -> failwith "Impossible: Head type is not an arrow"
             in
          let as_record qual e =
            match ((e.FStar_Extraction_ML_Syntax.expr), qual) with
            | (FStar_Extraction_ML_Syntax.MLE_CTor (uu____2772,args),Some
               (FStar_Syntax_Syntax.Record_ctor (tyname,fields))) ->
                let path =
                  FStar_List.map FStar_Ident.text_of_id tyname.FStar_Ident.ns
                   in
                let fields = record_fields fields args  in
                FStar_All.pipe_left
                  (FStar_Extraction_ML_Syntax.with_ty
                     e.FStar_Extraction_ML_Syntax.mlty)
                  (FStar_Extraction_ML_Syntax.MLE_Record (path, fields))
            | uu____2791 -> e  in
          let resugar_and_maybe_eta qual e =
            let uu____2804 = eta_args [] residualType  in
            match uu____2804 with
            | (eargs,tres) ->
                (match eargs with
                 | [] ->
                     FStar_Extraction_ML_Util.resugar_exp (as_record qual e)
                 | uu____2832 ->
                     let uu____2838 = FStar_List.unzip eargs  in
                     (match uu____2838 with
                      | (binders,eargs) ->
                          (match e.FStar_Extraction_ML_Syntax.expr with
                           | FStar_Extraction_ML_Syntax.MLE_CTor (head,args)
                               ->
                               let body =
                                 let _0_549 =
                                   let _0_548 =
                                     FStar_All.pipe_left
                                       (FStar_Extraction_ML_Syntax.with_ty
                                          tres)
                                       (FStar_Extraction_ML_Syntax.MLE_CTor
                                          (head,
                                            (FStar_List.append args eargs)))
                                      in
                                   FStar_All.pipe_left (as_record qual)
                                     _0_548
                                    in
                                 FStar_All.pipe_left
                                   FStar_Extraction_ML_Util.resugar_exp
                                   _0_549
                                  in
                               FStar_All.pipe_left
                                 (FStar_Extraction_ML_Syntax.with_ty
                                    e.FStar_Extraction_ML_Syntax.mlty)
                                 (FStar_Extraction_ML_Syntax.MLE_Fun
                                    (binders, body))
                           | uu____2866 ->
                               failwith "Impossible: Not a constructor")))
             in
          match ((mlAppExpr.FStar_Extraction_ML_Syntax.expr), qual) with
          | (uu____2868,None ) -> mlAppExpr
          | (FStar_Extraction_ML_Syntax.MLE_App
             ({
                FStar_Extraction_ML_Syntax.expr =
                  FStar_Extraction_ML_Syntax.MLE_Name mlp;
                FStar_Extraction_ML_Syntax.mlty = uu____2871;
                FStar_Extraction_ML_Syntax.loc = uu____2872;_},mle::args),Some
             (FStar_Syntax_Syntax.Record_projector (constrname,f))) ->
              let f =
                FStar_Ident.lid_of_ids
                  (FStar_List.append constrname.FStar_Ident.ns [f])
                 in
              let fn = FStar_Extraction_ML_Util.mlpath_of_lid f  in
              let proj = FStar_Extraction_ML_Syntax.MLE_Proj (mle, fn)  in
              let e =
                match args with
                | [] -> proj
                | uu____2890 ->
                    FStar_Extraction_ML_Syntax.MLE_App
                      (let _0_550 =
                         FStar_All.pipe_left
                           (FStar_Extraction_ML_Syntax.with_ty
                              FStar_Extraction_ML_Syntax.MLTY_Top) proj
                          in
                       (_0_550, args))
                 in
              FStar_Extraction_ML_Syntax.with_ty
                mlAppExpr.FStar_Extraction_ML_Syntax.mlty e
          | (FStar_Extraction_ML_Syntax.MLE_App
             ({
                FStar_Extraction_ML_Syntax.expr =
                  FStar_Extraction_ML_Syntax.MLE_Name mlp;
                FStar_Extraction_ML_Syntax.mlty = _;
                FStar_Extraction_ML_Syntax.loc = _;_},mlargs),Some
             (FStar_Syntax_Syntax.Data_ctor ))
            |(FStar_Extraction_ML_Syntax.MLE_App
              ({
                 FStar_Extraction_ML_Syntax.expr =
                   FStar_Extraction_ML_Syntax.MLE_Name mlp;
                 FStar_Extraction_ML_Syntax.mlty = _;
                 FStar_Extraction_ML_Syntax.loc = _;_},mlargs),Some
              (FStar_Syntax_Syntax.Record_ctor _)) ->
              let _0_551 =
                FStar_All.pipe_left
                  (FStar_Extraction_ML_Syntax.with_ty
                     mlAppExpr.FStar_Extraction_ML_Syntax.mlty)
                  (FStar_Extraction_ML_Syntax.MLE_CTor (mlp, mlargs))
                 in
              FStar_All.pipe_left (resugar_and_maybe_eta qual) _0_551
          | (FStar_Extraction_ML_Syntax.MLE_Name mlp,Some
             (FStar_Syntax_Syntax.Data_ctor ))
            |(FStar_Extraction_ML_Syntax.MLE_Name mlp,Some
              (FStar_Syntax_Syntax.Record_ctor _)) ->
              let _0_552 =
                FStar_All.pipe_left
                  (FStar_Extraction_ML_Syntax.with_ty
                     mlAppExpr.FStar_Extraction_ML_Syntax.mlty)
                  (FStar_Extraction_ML_Syntax.MLE_CTor (mlp, []))
                 in
              FStar_All.pipe_left (resugar_and_maybe_eta qual) _0_552
          | uu____2912 -> mlAppExpr
  
let maybe_downgrade_eff :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Extraction_ML_Syntax.e_tag ->
      FStar_Extraction_ML_Syntax.mlty -> FStar_Extraction_ML_Syntax.e_tag
  =
  fun g  ->
    fun f  ->
      fun t  ->
        let uu____2925 =
          (f = FStar_Extraction_ML_Syntax.E_GHOST) &&
            (type_leq g t FStar_Extraction_ML_Syntax.ml_unit_ty)
           in
        if uu____2925 then FStar_Extraction_ML_Syntax.E_PURE else f
  
let rec term_as_mlexpr :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.term ->
      (FStar_Extraction_ML_Syntax.mlexpr * FStar_Extraction_ML_Syntax.e_tag *
        FStar_Extraction_ML_Syntax.mlty)
  =
  fun g  ->
    fun t  ->
      let uu____2966 = term_as_mlexpr' g t  in
      match uu____2966 with
      | (e,tag,ty) ->
          let tag = maybe_downgrade_eff g tag ty  in
          (FStar_Extraction_ML_UEnv.debug g
             (fun u  ->
                FStar_Util.print_string
                  (let _0_555 = FStar_Syntax_Print.tag_of_term t  in
                   let _0_554 = FStar_Syntax_Print.term_to_string t  in
                   let _0_553 =
                     FStar_Extraction_ML_Code.string_of_mlty
                       g.FStar_Extraction_ML_UEnv.currentModule ty
                      in
                   FStar_Util.format4
                     "term_as_mlexpr (%s) :  %s has ML type %s and effect %s\n"
                     _0_555 _0_554 _0_553
                     (FStar_Extraction_ML_Util.eff_to_string tag)));
           erase g e ty tag)

and check_term_as_mlexpr :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.term ->
      FStar_Extraction_ML_Syntax.e_tag ->
        FStar_Extraction_ML_Syntax.mlty ->
          (FStar_Extraction_ML_Syntax.mlexpr *
            FStar_Extraction_ML_Syntax.mlty)
  =
  fun g  ->
    fun t  ->
      fun f  ->
        fun ty  ->
          let uu____2985 = check_term_as_mlexpr' g t f ty  in
          match uu____2985 with
          | (e,t) ->
              let uu____2992 = erase g e t f  in
              (match uu____2992 with | (r,uu____2999,t) -> (r, t))

and check_term_as_mlexpr' :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.term ->
      FStar_Extraction_ML_Syntax.e_tag ->
        FStar_Extraction_ML_Syntax.mlty ->
          (FStar_Extraction_ML_Syntax.mlexpr *
            FStar_Extraction_ML_Syntax.mlty)
  =
  fun g  ->
    fun e0  ->
      fun f  ->
        fun ty  ->
          let uu____3007 = term_as_mlexpr g e0  in
          match uu____3007 with
          | (e,tag,t) ->
              let tag = maybe_downgrade_eff g tag t  in
              if FStar_Extraction_ML_Util.eff_leq tag f
              then let _0_556 = maybe_coerce g e t ty  in (_0_556, ty)
              else err_unexpected_eff e0 f tag

and term_as_mlexpr' :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.term ->
      (FStar_Extraction_ML_Syntax.mlexpr * FStar_Extraction_ML_Syntax.e_tag *
        FStar_Extraction_ML_Syntax.mlty)
  =
  fun g  ->
    fun top  ->
      FStar_Extraction_ML_UEnv.debug g
        (fun u  ->
           FStar_Util.print_string
             (let _0_559 =
                FStar_Range.string_of_range top.FStar_Syntax_Syntax.pos  in
              let _0_558 = FStar_Syntax_Print.tag_of_term top  in
              let _0_557 = FStar_Syntax_Print.term_to_string top  in
              FStar_Util.format3 "%s: term_as_mlexpr' (%s) :  %s \n" _0_559
                _0_558 _0_557));
      (let t = FStar_Syntax_Subst.compress top  in
       match t.FStar_Syntax_Syntax.n with
       | FStar_Syntax_Syntax.Tm_unknown 
         |FStar_Syntax_Syntax.Tm_delayed _
          |FStar_Syntax_Syntax.Tm_uvar _|FStar_Syntax_Syntax.Tm_bvar _ ->
           failwith
             (let _0_560 = FStar_Syntax_Print.tag_of_term t  in
              FStar_Util.format1 "Impossible: Unexpected term: %s" _0_560)
       | FStar_Syntax_Syntax.Tm_type _
         |FStar_Syntax_Syntax.Tm_refine _|FStar_Syntax_Syntax.Tm_arrow _ ->
           (FStar_Extraction_ML_Syntax.ml_unit,
             FStar_Extraction_ML_Syntax.E_PURE,
             FStar_Extraction_ML_Syntax.ml_unit_ty)
       | FStar_Syntax_Syntax.Tm_meta
           (t,FStar_Syntax_Syntax.Meta_desugared
            (FStar_Syntax_Syntax.Mutable_alloc ))
           ->
           let uu____3047 = term_as_mlexpr' g t  in
           (match uu____3047 with
            | ({
                 FStar_Extraction_ML_Syntax.expr =
                   FStar_Extraction_ML_Syntax.MLE_Let
                   ((FStar_Extraction_ML_Syntax.NonRec ,flags,bodies),continuation);
                 FStar_Extraction_ML_Syntax.mlty = mlty;
                 FStar_Extraction_ML_Syntax.loc = loc;_},tag,typ)
                ->
                ({
                   FStar_Extraction_ML_Syntax.expr =
                     (FStar_Extraction_ML_Syntax.MLE_Let
                        ((FStar_Extraction_ML_Syntax.NonRec,
                           (FStar_Extraction_ML_Syntax.Mutable :: flags),
                           bodies), continuation));
                   FStar_Extraction_ML_Syntax.mlty = mlty;
                   FStar_Extraction_ML_Syntax.loc = loc
                 }, tag, typ)
            | uu____3074 -> failwith "impossible")
       | FStar_Syntax_Syntax.Tm_meta
           (t,FStar_Syntax_Syntax.Meta_monadic (m,uu____3083)) ->
           let t = FStar_Syntax_Subst.compress t  in
           (match t.FStar_Syntax_Syntax.n with
            | FStar_Syntax_Syntax.Tm_let ((false ,lb::[]),body) when
                FStar_Util.is_left lb.FStar_Syntax_Syntax.lbname ->
                let ed =
                  FStar_TypeChecker_Env.get_effect_decl
                    g.FStar_Extraction_ML_UEnv.tcenv m
                   in
                let uu____3107 =
                  let _0_561 =
                    FStar_All.pipe_right ed.FStar_Syntax_Syntax.qualifiers
                      (FStar_List.contains FStar_Syntax_Syntax.Reifiable)
                     in
                  FStar_All.pipe_right _0_561 Prims.op_Negation  in
                if uu____3107
                then term_as_mlexpr' g t
                else
                  (let ml_result_ty_1 =
                     term_as_mlty g lb.FStar_Syntax_Syntax.lbtyp  in
                   let uu____3114 =
                     term_as_mlexpr g lb.FStar_Syntax_Syntax.lbdef  in
                   match uu____3114 with
                   | (comp_1,uu____3122,uu____3123) ->
                       let uu____3124 =
                         let k =
                           let _0_564 =
                             let _0_563 =
                               let _0_562 =
                                 FStar_Util.left
                                   lb.FStar_Syntax_Syntax.lbname
                                  in
                               FStar_All.pipe_right _0_562
                                 FStar_Syntax_Syntax.mk_binder
                                in
                             [_0_563]  in
                           FStar_Syntax_Util.abs _0_564 body None  in
                         let uu____3133 = term_as_mlexpr g k  in
                         match uu____3133 with
                         | (ml_k,uu____3140,t_k) ->
                             let m_2 =
                               match t_k with
                               | FStar_Extraction_ML_Syntax.MLTY_Fun
                                   (uu____3143,uu____3144,m_2) -> m_2
                               | uu____3146 -> failwith "Impossible"  in
                             (ml_k, m_2)
                          in
                       (match uu____3124 with
                        | (ml_k,ty) ->
                            let bind =
                              let _0_566 =
                                FStar_Extraction_ML_Syntax.MLE_Name
                                  (let _0_565 =
                                     FStar_Extraction_ML_UEnv.monad_op_name
                                       ed "bind"
                                      in
                                   FStar_All.pipe_right _0_565 Prims.fst)
                                 in
                              FStar_All.pipe_left
                                (FStar_Extraction_ML_Syntax.with_ty
                                   FStar_Extraction_ML_Syntax.MLTY_Top)
                                _0_566
                               in
                            let _0_567 =
                              FStar_All.pipe_left
                                (FStar_Extraction_ML_Syntax.with_ty ty)
                                (FStar_Extraction_ML_Syntax.MLE_App
                                   (bind, [comp_1; ml_k]))
                               in
                            (_0_567, FStar_Extraction_ML_Syntax.E_IMPURE, ty)))
            | uu____3156 -> term_as_mlexpr' g t)
       | FStar_Syntax_Syntax.Tm_meta (t,_)|FStar_Syntax_Syntax.Tm_uinst (t,_)
           -> term_as_mlexpr' g t
       | FStar_Syntax_Syntax.Tm_constant c ->
           let uu____3169 =
             FStar_TypeChecker_TcTerm.type_of_tot_term
               g.FStar_Extraction_ML_UEnv.tcenv t
              in
           (match uu____3169 with
            | (uu____3176,ty,uu____3178) ->
                let ml_ty = term_as_mlty g ty  in
                let _0_571 =
                  let _0_570 =
                    let _0_569 =
                      FStar_Extraction_ML_Util.mlconst_of_const'
                        t.FStar_Syntax_Syntax.pos c
                       in
                    FStar_All.pipe_left
                      (fun _0_568  ->
                         FStar_Extraction_ML_Syntax.MLE_Const _0_568) _0_569
                     in
                  FStar_Extraction_ML_Syntax.with_ty ml_ty _0_570  in
                (_0_571, FStar_Extraction_ML_Syntax.E_PURE, ml_ty))
       | FStar_Syntax_Syntax.Tm_name _|FStar_Syntax_Syntax.Tm_fvar _ ->
           let uu____3182 = is_type g t  in
           if uu____3182
           then
             (FStar_Extraction_ML_Syntax.ml_unit,
               FStar_Extraction_ML_Syntax.E_PURE,
               FStar_Extraction_ML_Syntax.ml_unit_ty)
           else
             (let uu____3187 = FStar_Extraction_ML_UEnv.lookup_term g t  in
              match uu____3187 with
              | (FStar_Util.Inl uu____3194,uu____3195) ->
                  (FStar_Extraction_ML_Syntax.ml_unit,
                    FStar_Extraction_ML_Syntax.E_PURE,
                    FStar_Extraction_ML_Syntax.ml_unit_ty)
              | (FStar_Util.Inr (x,mltys,uu____3214),qual) ->
                  (match mltys with
                   | ([],t) when t = FStar_Extraction_ML_Syntax.ml_unit_ty ->
                       (FStar_Extraction_ML_Syntax.ml_unit,
                         FStar_Extraction_ML_Syntax.E_PURE, t)
                   | ([],t) ->
                       let _0_572 =
                         maybe_eta_data_and_project_record g qual t x  in
                       (_0_572, FStar_Extraction_ML_Syntax.E_PURE, t)
                   | uu____3237 -> err_uninst g t mltys t))
       | FStar_Syntax_Syntax.Tm_abs (bs,body,copt) ->
           let uu____3266 = FStar_Syntax_Subst.open_term bs body  in
           (match uu____3266 with
            | (bs,body) ->
                let uu____3274 = binders_as_ml_binders g bs  in
                (match uu____3274 with
                 | (ml_bs,env) ->
                     let uu____3291 = term_as_mlexpr env body  in
                     (match uu____3291 with
                      | (ml_body,f,t) ->
                          let uu____3301 =
                            FStar_List.fold_right
                              (fun uu____3308  ->
                                 fun uu____3309  ->
                                   match (uu____3308, uu____3309) with
                                   | ((uu____3320,targ),(f,t)) ->
                                       (FStar_Extraction_ML_Syntax.E_PURE,
                                         (FStar_Extraction_ML_Syntax.MLTY_Fun
                                            (targ, f, t)))) ml_bs (f, t)
                             in
                          (match uu____3301 with
                           | (f,tfun) ->
                               let _0_573 =
                                 FStar_All.pipe_left
                                   (FStar_Extraction_ML_Syntax.with_ty tfun)
                                   (FStar_Extraction_ML_Syntax.MLE_Fun
                                      (ml_bs, ml_body))
                                  in
                               (_0_573, f, tfun)))))
       | FStar_Syntax_Syntax.Tm_app
           ({
              FStar_Syntax_Syntax.n = FStar_Syntax_Syntax.Tm_constant
                (FStar_Const.Const_reify );
              FStar_Syntax_Syntax.tk = uu____3336;
              FStar_Syntax_Syntax.pos = uu____3337;
              FStar_Syntax_Syntax.vars = uu____3338;_},t::[])
           ->
           let uu____3361 = term_as_mlexpr' g (Prims.fst t)  in
           (match uu____3361 with
            | (ml,e_tag,mlty) ->
                (ml, FStar_Extraction_ML_Syntax.E_PURE, mlty))
       | FStar_Syntax_Syntax.Tm_app
           ({
              FStar_Syntax_Syntax.n = FStar_Syntax_Syntax.Tm_constant
                (FStar_Const.Const_reflect uu____3373);
              FStar_Syntax_Syntax.tk = uu____3374;
              FStar_Syntax_Syntax.pos = uu____3375;
              FStar_Syntax_Syntax.vars = uu____3376;_},t::[])
           ->
           let uu____3399 = term_as_mlexpr' g (Prims.fst t)  in
           (match uu____3399 with
            | (ml,e_tag,mlty) ->
                (ml, FStar_Extraction_ML_Syntax.E_IMPURE, mlty))
       | FStar_Syntax_Syntax.Tm_app (head,args) ->
           let is_total uu___137_3435 =
             match uu___137_3435 with
             | FStar_Util.Inl l -> FStar_Syntax_Util.is_total_lcomp l
             | FStar_Util.Inr (l,flags) ->
                 (FStar_Ident.lid_equals l FStar_Syntax_Const.effect_Tot_lid)
                   ||
                   (FStar_All.pipe_right flags
                      (FStar_List.existsb
                         (fun uu___136_3453  ->
                            match uu___136_3453 with
                            | FStar_Syntax_Syntax.TOTAL  -> true
                            | uu____3454 -> false)))
              in
           let uu____3455 =
             let _0_574 =
               (FStar_Syntax_Subst.compress head).FStar_Syntax_Syntax.n  in
             ((head.FStar_Syntax_Syntax.n), _0_574)  in
           (match uu____3455 with
            | (FStar_Syntax_Syntax.Tm_uvar uu____3461,uu____3462) ->
                let t =
                  FStar_TypeChecker_Normalize.normalize
                    [FStar_TypeChecker_Normalize.Beta;
                    FStar_TypeChecker_Normalize.Iota;
                    FStar_TypeChecker_Normalize.Zeta;
                    FStar_TypeChecker_Normalize.EraseUniverses;
                    FStar_TypeChecker_Normalize.AllowUnboundUniverses]
                    g.FStar_Extraction_ML_UEnv.tcenv t
                   in
                term_as_mlexpr' g t
            | (uu____3472,FStar_Syntax_Syntax.Tm_abs (bs,uu____3474,Some lc))
                when is_total lc ->
                let t =
                  FStar_TypeChecker_Normalize.normalize
                    [FStar_TypeChecker_Normalize.Beta;
                    FStar_TypeChecker_Normalize.Iota;
                    FStar_TypeChecker_Normalize.Zeta;
                    FStar_TypeChecker_Normalize.EraseUniverses;
                    FStar_TypeChecker_Normalize.AllowUnboundUniverses]
                    g.FStar_Extraction_ML_UEnv.tcenv t
                   in
                term_as_mlexpr' g t
            | uu____3503 ->
                let rec extract_app is_data uu____3531 uu____3532 restArgs =
                  match (uu____3531, uu____3532) with
                  | ((mlhead,mlargs_f),(f,t)) ->
                      (match (restArgs, t) with
                       | ([],uu____3580) ->
                           let evaluation_order_guaranteed =
                             (((FStar_List.length mlargs_f) =
                                 (Prims.parse_int "1"))
                                ||
                                (FStar_Extraction_ML_Util.codegen_fsharp ()))
                               ||
                               (match head.FStar_Syntax_Syntax.n with
                                | FStar_Syntax_Syntax.Tm_fvar fv ->
                                    (FStar_Syntax_Syntax.fv_eq_lid fv
                                       FStar_Syntax_Const.op_And)
                                      ||
                                      (FStar_Syntax_Syntax.fv_eq_lid fv
                                         FStar_Syntax_Const.op_Or)
                                | uu____3594 -> false)
                              in
                           let uu____3595 =
                             if evaluation_order_guaranteed
                             then
                               let _0_575 =
                                 FStar_All.pipe_right
                                   (FStar_List.rev mlargs_f)
                                   (FStar_List.map Prims.fst)
                                  in
                               ([], _0_575)
                             else
                               FStar_List.fold_left
                                 (fun uu____3631  ->
                                    fun uu____3632  ->
                                      match (uu____3631, uu____3632) with
                                      | ((lbs,out_args),(arg,f)) ->
                                          if
                                            (f =
                                               FStar_Extraction_ML_Syntax.E_PURE)
                                              ||
                                              (f =
                                                 FStar_Extraction_ML_Syntax.E_GHOST)
                                          then (lbs, (arg :: out_args))
                                          else
                                            (let x =
                                               FStar_Extraction_ML_Syntax.gensym
                                                 ()
                                                in
                                             let _0_577 =
                                               let _0_576 =
                                                 FStar_All.pipe_left
                                                   (FStar_Extraction_ML_Syntax.with_ty
                                                      arg.FStar_Extraction_ML_Syntax.mlty)
                                                   (FStar_Extraction_ML_Syntax.MLE_Var
                                                      x)
                                                  in
                                               _0_576 :: out_args  in
                                             (((x, arg) :: lbs), _0_577)))
                                 ([], []) mlargs_f
                              in
                           (match uu____3595 with
                            | (lbs,mlargs) ->
                                let app =
                                  let _0_578 =
                                    FStar_All.pipe_left
                                      (FStar_Extraction_ML_Syntax.with_ty t)
                                      (FStar_Extraction_ML_Syntax.MLE_App
                                         (mlhead, mlargs))
                                     in
                                  FStar_All.pipe_left
                                    (maybe_eta_data_and_project_record g
                                       is_data t) _0_578
                                   in
                                let l_app =
                                  FStar_List.fold_right
                                    (fun uu____3717  ->
                                       fun out  ->
                                         match uu____3717 with
                                         | (x,arg) ->
                                             FStar_All.pipe_left
                                               (FStar_Extraction_ML_Syntax.with_ty
                                                  out.FStar_Extraction_ML_Syntax.mlty)
                                               (mk_MLE_Let false
                                                  (FStar_Extraction_ML_Syntax.NonRec,
                                                    [],
                                                    [{
                                                       FStar_Extraction_ML_Syntax.mllb_name
                                                         = x;
                                                       FStar_Extraction_ML_Syntax.mllb_tysc
                                                         =
                                                         (Some
                                                            ([],
                                                              (arg.FStar_Extraction_ML_Syntax.mlty)));
                                                       FStar_Extraction_ML_Syntax.mllb_add_unit
                                                         = false;
                                                       FStar_Extraction_ML_Syntax.mllb_def
                                                         = arg;
                                                       FStar_Extraction_ML_Syntax.print_typ
                                                         = true
                                                     }]) out)) lbs app
                                   in
                                (l_app, f, t))
                       | ((arg,uu____3730)::rest,FStar_Extraction_ML_Syntax.MLTY_Fun
                          (formal_t,f',t)) when is_type g arg ->
                           let uu____3748 =
                             type_leq g formal_t
                               FStar_Extraction_ML_Syntax.ml_unit_ty
                              in
                           if uu____3748
                           then
                             let _0_580 =
                               let _0_579 =
                                 FStar_Extraction_ML_Util.join
                                   arg.FStar_Syntax_Syntax.pos f f'
                                  in
                               (_0_579, t)  in
                             extract_app is_data
                               (mlhead,
                                 ((FStar_Extraction_ML_Syntax.ml_unit,
                                    FStar_Extraction_ML_Syntax.E_PURE) ::
                                 mlargs_f)) _0_580 rest
                           else
                             failwith
                               (let _0_584 =
                                  FStar_Extraction_ML_Code.string_of_mlexpr
                                    g.FStar_Extraction_ML_UEnv.currentModule
                                    mlhead
                                   in
                                let _0_583 =
                                  FStar_Syntax_Print.term_to_string arg  in
                                let _0_582 =
                                  FStar_Syntax_Print.tag_of_term arg  in
                                let _0_581 =
                                  FStar_Extraction_ML_Code.string_of_mlty
                                    g.FStar_Extraction_ML_UEnv.currentModule
                                    formal_t
                                   in
                                FStar_Util.format4
                                  "Impossible: ill-typed application:\n\thead=%s, arg=%s, tag=%s\n\texpected type unit, got %s"
                                  _0_584 _0_583 _0_582 _0_581)
                       | ((e0,uu____3762)::rest,FStar_Extraction_ML_Syntax.MLTY_Fun
                          (tExpected,f',t)) ->
                           let r = e0.FStar_Syntax_Syntax.pos  in
                           let uu____3781 = term_as_mlexpr g e0  in
                           (match uu____3781 with
                            | (e0,f0,tInferred) ->
                                let e0 =
                                  maybe_coerce g e0 tInferred tExpected  in
                                let _0_586 =
                                  let _0_585 =
                                    FStar_Extraction_ML_Util.join_l r
                                      [f; f'; f0]
                                     in
                                  (_0_585, t)  in
                                extract_app is_data
                                  (mlhead, ((e0, f0) :: mlargs_f)) _0_586
                                  rest)
                       | uu____3797 ->
                           let uu____3804 =
                             FStar_Extraction_ML_Util.udelta_unfold g t  in
                           (match uu____3804 with
                            | Some t ->
                                extract_app is_data (mlhead, mlargs_f) 
                                  (f, t) restArgs
                            | None  ->
                                err_ill_typed_application g top restArgs t))
                   in
                let extract_app_maybe_projector is_data mlhead uu____3840
                  args =
                  match uu____3840 with
                  | (f,t) ->
                      (match is_data with
                       | Some (FStar_Syntax_Syntax.Record_projector
                           uu____3859) ->
                           let rec remove_implicits args f t =
                             match (args, t) with
                             | ((a0,Some (FStar_Syntax_Syntax.Implicit
                                 uu____3909))::args,FStar_Extraction_ML_Syntax.MLTY_Fun
                                (uu____3911,f',t)) ->
                                 let _0_587 =
                                   FStar_Extraction_ML_Util.join
                                     a0.FStar_Syntax_Syntax.pos f f'
                                    in
                                 remove_implicits args _0_587 t
                             | uu____3936 -> (args, f, t)  in
                           let uu____3951 = remove_implicits args f t  in
                           (match uu____3951 with
                            | (args,f,t) ->
                                extract_app is_data (mlhead, []) (f, t) args)
                       | uu____3984 ->
                           extract_app is_data (mlhead, []) (f, t) args)
                   in
                let uu____3991 = is_type g t  in
                if uu____3991
                then
                  (FStar_Extraction_ML_Syntax.ml_unit,
                    FStar_Extraction_ML_Syntax.E_PURE,
                    FStar_Extraction_ML_Syntax.ml_unit_ty)
                else
                  (let head = FStar_Syntax_Util.un_uinst head  in
                   match head.FStar_Syntax_Syntax.n with
                   | FStar_Syntax_Syntax.Tm_name _
                     |FStar_Syntax_Syntax.Tm_fvar _ ->
                       let uu____4002 =
                         let uu____4009 =
                           FStar_Extraction_ML_UEnv.lookup_term g head  in
                         match uu____4009 with
                         | (FStar_Util.Inr u,q) -> (u, q)
                         | uu____4042 -> failwith "FIXME Ty"  in
                       (match uu____4002 with
                        | ((head_ml,(vars,t),inst_ok),qual) ->
                            let has_typ_apps =
                              match args with
                              | (a,uu____4071)::uu____4072 -> is_type g a
                              | uu____4086 -> false  in
                            let uu____4092 =
                              match vars with
                              | uu____4109::uu____4110 when
                                  (Prims.op_Negation has_typ_apps) && inst_ok
                                  -> (head_ml, t, args)
                              | uu____4117 ->
                                  let n = FStar_List.length vars  in
                                  if n <= (FStar_List.length args)
                                  then
                                    let uu____4137 =
                                      FStar_Util.first_N n args  in
                                    (match uu____4137 with
                                     | (prefix,rest) ->
                                         let prefixAsMLTypes =
                                           FStar_List.map
                                             (fun uu____4190  ->
                                                match uu____4190 with
                                                | (x,uu____4194) ->
                                                    term_as_mlty g x) prefix
                                            in
                                         let t =
                                           instantiate (vars, t)
                                             prefixAsMLTypes
                                            in
                                         let head =
                                           match head_ml.FStar_Extraction_ML_Syntax.expr
                                           with
                                           | FStar_Extraction_ML_Syntax.MLE_Name
                                             _
                                             |FStar_Extraction_ML_Syntax.MLE_Var
                                             _ ->
                                               let uu___141_4199 = head_ml
                                                  in
                                               {
                                                 FStar_Extraction_ML_Syntax.expr
                                                   =
                                                   (uu___141_4199.FStar_Extraction_ML_Syntax.expr);
                                                 FStar_Extraction_ML_Syntax.mlty
                                                   = t;
                                                 FStar_Extraction_ML_Syntax.loc
                                                   =
                                                   (uu___141_4199.FStar_Extraction_ML_Syntax.loc)
                                               }
                                           | FStar_Extraction_ML_Syntax.MLE_App
                                               (head,{
                                                       FStar_Extraction_ML_Syntax.expr
                                                         =
                                                         FStar_Extraction_ML_Syntax.MLE_Const
                                                         (FStar_Extraction_ML_Syntax.MLC_Unit
                                                         );
                                                       FStar_Extraction_ML_Syntax.mlty
                                                         = uu____4201;
                                                       FStar_Extraction_ML_Syntax.loc
                                                         = uu____4202;_}::[])
                                               ->
                                               FStar_All.pipe_right
                                                 (FStar_Extraction_ML_Syntax.MLE_App
                                                    ((let uu___142_4205 =
                                                        head  in
                                                      {
                                                        FStar_Extraction_ML_Syntax.expr
                                                          =
                                                          (uu___142_4205.FStar_Extraction_ML_Syntax.expr);
                                                        FStar_Extraction_ML_Syntax.mlty
                                                          =
                                                          (FStar_Extraction_ML_Syntax.MLTY_Fun
                                                             (FStar_Extraction_ML_Syntax.ml_unit_ty,
                                                               FStar_Extraction_ML_Syntax.E_PURE,
                                                               t));
                                                        FStar_Extraction_ML_Syntax.loc
                                                          =
                                                          (uu___142_4205.FStar_Extraction_ML_Syntax.loc)
                                                      }),
                                                      [FStar_Extraction_ML_Syntax.ml_unit]))
                                                 (FStar_Extraction_ML_Syntax.with_ty
                                                    t)
                                           | uu____4206 ->
                                               failwith
                                                 "Impossible: Unexpected head term"
                                            in
                                         (head, t, rest))
                                  else err_uninst g head (vars, t) top
                               in
                            (match uu____4092 with
                             | (head_ml,head_t,args) ->
                                 (match args with
                                  | [] ->
                                      let _0_588 =
                                        maybe_eta_data_and_project_record g
                                          qual head_t head_ml
                                         in
                                      (_0_588,
                                        FStar_Extraction_ML_Syntax.E_PURE,
                                        head_t)
                                  | uu____4244 ->
                                      extract_app_maybe_projector qual
                                        head_ml
                                        (FStar_Extraction_ML_Syntax.E_PURE,
                                          head_t) args)))
                   | uu____4250 ->
                       let uu____4251 = term_as_mlexpr g head  in
                       (match uu____4251 with
                        | (head,f,t) ->
                            extract_app_maybe_projector None head (f, t) args)))
       | FStar_Syntax_Syntax.Tm_ascribed (e0,tc,f) ->
           let t =
             match tc with
             | FStar_Util.Inl t -> term_as_mlty g t
             | FStar_Util.Inr c ->
                 let _0_589 =
                   FStar_TypeChecker_Env.result_typ
                     g.FStar_Extraction_ML_UEnv.tcenv c
                    in
                 term_as_mlty g _0_589
              in
           let f =
             match f with
             | None  -> failwith "Ascription node with an empty effect label"
             | Some l -> effect_as_etag g l  in
           let uu____4299 = check_term_as_mlexpr g e0 f t  in
           (match uu____4299 with | (e,t) -> (e, f, t))
       | FStar_Syntax_Syntax.Tm_let ((is_rec,lbs),e') ->
           let top_level = FStar_Syntax_Syntax.is_top_level lbs  in
           let uu____4320 =
             if is_rec
             then FStar_Syntax_Subst.open_let_rec lbs e'
             else
               (let uu____4328 = FStar_Syntax_Syntax.is_top_level lbs  in
                if uu____4328
                then (lbs, e')
                else
                  (let lb = FStar_List.hd lbs  in
                   let x =
                     FStar_Syntax_Syntax.freshen_bv
                       (FStar_Util.left lb.FStar_Syntax_Syntax.lbname)
                      in
                   let lb =
                     let uu___143_4339 = lb  in
                     {
                       FStar_Syntax_Syntax.lbname = (FStar_Util.Inl x);
                       FStar_Syntax_Syntax.lbunivs =
                         (uu___143_4339.FStar_Syntax_Syntax.lbunivs);
                       FStar_Syntax_Syntax.lbtyp =
                         (uu___143_4339.FStar_Syntax_Syntax.lbtyp);
                       FStar_Syntax_Syntax.lbeff =
                         (uu___143_4339.FStar_Syntax_Syntax.lbeff);
                       FStar_Syntax_Syntax.lbdef =
                         (uu___143_4339.FStar_Syntax_Syntax.lbdef)
                     }  in
                   let e' =
                     FStar_Syntax_Subst.subst
                       [FStar_Syntax_Syntax.DB ((Prims.parse_int "0"), x)] e'
                      in
                   ([lb], e')))
              in
           (match uu____4320 with
            | (lbs,e') ->
                let lbs =
                  if top_level
                  then
                    FStar_All.pipe_right lbs
                      (FStar_List.map
                         (fun lb  ->
                            let tcenv =
                              let _0_590 =
                                FStar_Ident.lid_of_path
                                  (FStar_List.append
                                     (Prims.fst
                                        g.FStar_Extraction_ML_UEnv.currentModule)
                                     [Prims.snd
                                        g.FStar_Extraction_ML_UEnv.currentModule])
                                  FStar_Range.dummyRange
                                 in
                              FStar_TypeChecker_Env.set_current_module
                                g.FStar_Extraction_ML_UEnv.tcenv _0_590
                               in
                            FStar_Extraction_ML_UEnv.debug g
                              (fun uu____4359  ->
                                 FStar_Options.set_option "debug_level"
                                   (FStar_Options.List
                                      [FStar_Options.String "Norm";
                                      FStar_Options.String "Extraction"]));
                            (let lbdef =
                               let uu____4363 = FStar_Options.ml_ish ()  in
                               if uu____4363
                               then lb.FStar_Syntax_Syntax.lbdef
                               else
                                 FStar_TypeChecker_Normalize.normalize
                                   [FStar_TypeChecker_Normalize.AllowUnboundUniverses;
                                   FStar_TypeChecker_Normalize.EraseUniverses;
                                   FStar_TypeChecker_Normalize.Inlining;
                                   FStar_TypeChecker_Normalize.Eager_unfolding;
                                   FStar_TypeChecker_Normalize.Exclude
                                     FStar_TypeChecker_Normalize.Zeta;
                                   FStar_TypeChecker_Normalize.PureSubtermsWithinComputations;
                                   FStar_TypeChecker_Normalize.Primops] tcenv
                                   lb.FStar_Syntax_Syntax.lbdef
                                in
                             let uu___144_4367 = lb  in
                             {
                               FStar_Syntax_Syntax.lbname =
                                 (uu___144_4367.FStar_Syntax_Syntax.lbname);
                               FStar_Syntax_Syntax.lbunivs =
                                 (uu___144_4367.FStar_Syntax_Syntax.lbunivs);
                               FStar_Syntax_Syntax.lbtyp =
                                 (uu___144_4367.FStar_Syntax_Syntax.lbtyp);
                               FStar_Syntax_Syntax.lbeff =
                                 (uu___144_4367.FStar_Syntax_Syntax.lbeff);
                               FStar_Syntax_Syntax.lbdef = lbdef
                             })))
                  else lbs  in
                let maybe_generalize uu____4381 =
                  match uu____4381 with
                  | { FStar_Syntax_Syntax.lbname = lbname_;
                      FStar_Syntax_Syntax.lbunivs = uu____4392;
                      FStar_Syntax_Syntax.lbtyp = t;
                      FStar_Syntax_Syntax.lbeff = lbeff;
                      FStar_Syntax_Syntax.lbdef = e;_} ->
                      let f_e = effect_as_etag g lbeff  in
                      let t = FStar_Syntax_Subst.compress t  in
                      (match t.FStar_Syntax_Syntax.n with
                       | FStar_Syntax_Syntax.Tm_arrow (bs,c) when
                           let _0_591 = FStar_List.hd bs  in
                           FStar_All.pipe_right _0_591 (is_type_binder g) ->
                           let uu____4439 = FStar_Syntax_Subst.open_comp bs c
                              in
                           (match uu____4439 with
                            | (bs,c) ->
                                let uu____4453 =
                                  let uu____4456 =
                                    FStar_Util.prefix_until
                                      (fun x  ->
                                         Prims.op_Negation
                                           (is_type_binder g x)) bs
                                     in
                                  match uu____4456 with
                                  | None  ->
                                      let _0_592 =
                                        FStar_TypeChecker_Env.result_typ
                                          g.FStar_Extraction_ML_UEnv.tcenv c
                                         in
                                      (bs, _0_592)
                                  | Some (bs,b,rest) ->
                                      let _0_593 =
                                        FStar_Syntax_Util.arrow (b :: rest) c
                                         in
                                      (bs, _0_593)
                                   in
                                (match uu____4453 with
                                 | (tbinders,tbody) ->
                                     let n_tbinders =
                                       FStar_List.length tbinders  in
                                     let e =
                                       let _0_594 = normalize_abs e  in
                                       FStar_All.pipe_right _0_594
                                         FStar_Syntax_Util.unmeta
                                        in
                                     (match e.FStar_Syntax_Syntax.n with
                                      | FStar_Syntax_Syntax.Tm_abs
                                          (bs,body,uu____4549) ->
                                          let uu____4572 =
                                            FStar_Syntax_Subst.open_term bs
                                              body
                                             in
                                          (match uu____4572 with
                                           | (bs,body) ->
                                               if
                                                 n_tbinders <=
                                                   (FStar_List.length bs)
                                               then
                                                 let uu____4602 =
                                                   FStar_Util.first_N
                                                     n_tbinders bs
                                                    in
                                                 (match uu____4602 with
                                                  | (targs,rest_args) ->
                                                      let expected_source_ty
                                                        =
                                                        let s =
                                                          FStar_List.map2
                                                            (fun uu____4645 
                                                               ->
                                                               fun uu____4646
                                                                  ->
                                                                 match 
                                                                   (uu____4645,
                                                                    uu____4646)
                                                                 with
                                                                 | ((x,uu____4656),
                                                                    (y,uu____4658))
                                                                    ->
                                                                    FStar_Syntax_Syntax.NT
                                                                    (let _0_595
                                                                    =
                                                                    FStar_Syntax_Syntax.bv_to_name
                                                                    y  in
                                                                    (x,
                                                                    _0_595)))
                                                            tbinders targs
                                                           in
                                                        FStar_Syntax_Subst.subst
                                                          s tbody
                                                         in
                                                      let env =
                                                        FStar_List.fold_left
                                                          (fun env  ->
                                                             fun uu____4667 
                                                               ->
                                                               match uu____4667
                                                               with
                                                               | (a,uu____4671)
                                                                   ->
                                                                   FStar_Extraction_ML_UEnv.extend_ty
                                                                    env a
                                                                    None) g
                                                          targs
                                                         in
                                                      let expected_t =
                                                        term_as_mlty env
                                                          expected_source_ty
                                                         in
                                                      let polytype =
                                                        let _0_596 =
                                                          FStar_All.pipe_right
                                                            targs
                                                            (FStar_List.map
                                                               (fun
                                                                  uu____4692 
                                                                  ->
                                                                  match uu____4692
                                                                  with
                                                                  | (x,uu____4698)
                                                                    ->
                                                                    FStar_Extraction_ML_UEnv.bv_as_ml_tyvar
                                                                    x))
                                                           in
                                                        (_0_596, expected_t)
                                                         in
                                                      let add_unit =
                                                        match rest_args with
                                                        | [] ->
                                                            Prims.op_Negation
                                                              (is_fstar_value
                                                                 body)
                                                        | uu____4702 -> false
                                                         in
                                                      let rest_args =
                                                        if add_unit
                                                        then unit_binder ::
                                                          rest_args
                                                        else rest_args  in
                                                      let body =
                                                        match rest_args with
                                                        | [] -> body
                                                        | uu____4711 ->
                                                            FStar_Syntax_Util.abs
                                                              rest_args body
                                                              None
                                                         in
                                                      (lbname_, f_e,
                                                        (t,
                                                          (targs, polytype)),
                                                        add_unit, body))
                                               else
                                                 failwith
                                                   "Not enough type binders")
                                      | FStar_Syntax_Syntax.Tm_uinst _
                                        |FStar_Syntax_Syntax.Tm_fvar _
                                         |FStar_Syntax_Syntax.Tm_name _ ->
                                          let env =
                                            FStar_List.fold_left
                                              (fun env  ->
                                                 fun uu____4767  ->
                                                   match uu____4767 with
                                                   | (a,uu____4771) ->
                                                       FStar_Extraction_ML_UEnv.extend_ty
                                                         env a None) g
                                              tbinders
                                             in
                                          let expected_t =
                                            term_as_mlty env tbody  in
                                          let polytype =
                                            let _0_597 =
                                              FStar_All.pipe_right tbinders
                                                (FStar_List.map
                                                   (fun uu____4789  ->
                                                      match uu____4789 with
                                                      | (x,uu____4795) ->
                                                          FStar_Extraction_ML_UEnv.bv_as_ml_tyvar
                                                            x))
                                               in
                                            (_0_597, expected_t)  in
                                          let args =
                                            FStar_All.pipe_right tbinders
                                              (FStar_List.map
                                                 (fun uu____4801  ->
                                                    match uu____4801 with
                                                    | (bv,uu____4805) ->
                                                        let _0_598 =
                                                          FStar_Syntax_Syntax.bv_to_name
                                                            bv
                                                           in
                                                        FStar_All.pipe_right
                                                          _0_598
                                                          FStar_Syntax_Syntax.as_arg))
                                             in
                                          let e =
                                            (FStar_Syntax_Syntax.mk
                                               (FStar_Syntax_Syntax.Tm_app
                                                  (e, args))) None
                                              e.FStar_Syntax_Syntax.pos
                                             in
                                          (lbname_, f_e,
                                            (t, (tbinders, polytype)), false,
                                            e)
                                      | uu____4843 -> err_value_restriction e)))
                       | uu____4853 ->
                           let expected_t = term_as_mlty g t  in
                           (lbname_, f_e, (t, ([], ([], expected_t))), false,
                             e))
                   in
                let check_lb env uu____4910 =
                  match uu____4910 with
                  | (nm,(lbname,f,(t,(targs,polytype)),add_unit,e)) ->
                      let env =
                        FStar_List.fold_left
                          (fun env  ->
                             fun uu____4981  ->
                               match uu____4981 with
                               | (a,uu____4985) ->
                                   FStar_Extraction_ML_UEnv.extend_ty env a
                                     None) env targs
                         in
                      let expected_t =
                        if add_unit
                        then
                          FStar_Extraction_ML_Syntax.MLTY_Fun
                            (FStar_Extraction_ML_Syntax.ml_unit_ty,
                              FStar_Extraction_ML_Syntax.E_PURE,
                              (Prims.snd polytype))
                        else Prims.snd polytype  in
                      let uu____4988 =
                        check_term_as_mlexpr env e f expected_t  in
                      (match uu____4988 with
                       | (e,uu____4994) ->
                           let f = maybe_downgrade_eff env f expected_t  in
                           (f,
                             {
                               FStar_Extraction_ML_Syntax.mllb_name = nm;
                               FStar_Extraction_ML_Syntax.mllb_tysc =
                                 (Some polytype);
                               FStar_Extraction_ML_Syntax.mllb_add_unit =
                                 add_unit;
                               FStar_Extraction_ML_Syntax.mllb_def = e;
                               FStar_Extraction_ML_Syntax.print_typ = true
                             }))
                   in
                let lbs =
                  FStar_All.pipe_right lbs (FStar_List.map maybe_generalize)
                   in
                let uu____5029 =
                  FStar_List.fold_right
                    (fun lb  ->
                       fun uu____5068  ->
                         match uu____5068 with
                         | (env,lbs) ->
                             let uu____5132 = lb  in
                             (match uu____5132 with
                              | (lbname,uu____5157,(t,(uu____5159,polytype)),add_unit,uu____5162)
                                  ->
                                  let uu____5169 =
                                    FStar_Extraction_ML_UEnv.extend_lb env
                                      lbname t polytype add_unit true
                                     in
                                  (match uu____5169 with
                                   | (env,nm) -> (env, ((nm, lb) :: lbs)))))
                    lbs (g, [])
                   in
                (match uu____5029 with
                 | (env_body,lbs) ->
                     let env_def = if is_rec then env_body else g  in
                     let lbs =
                       FStar_All.pipe_right lbs
                         (FStar_List.map (check_lb env_def))
                        in
                     let e'_rng = e'.FStar_Syntax_Syntax.pos  in
                     let uu____5312 = term_as_mlexpr env_body e'  in
                     (match uu____5312 with
                      | (e',f',t') ->
                          let f =
                            let _0_600 =
                              let _0_599 = FStar_List.map Prims.fst lbs  in
                              f' :: _0_599  in
                            FStar_Extraction_ML_Util.join_l e'_rng _0_600  in
                          let is_rec =
                            if is_rec = true
                            then FStar_Extraction_ML_Syntax.Rec
                            else FStar_Extraction_ML_Syntax.NonRec  in
                          let _0_605 =
                            let _0_604 =
                              let _0_602 =
                                let _0_601 = FStar_List.map Prims.snd lbs  in
                                (is_rec, [], _0_601)  in
                              mk_MLE_Let top_level _0_602 e'  in
                            let _0_603 =
                              FStar_Extraction_ML_Util.mlloc_of_range
                                t.FStar_Syntax_Syntax.pos
                               in
                            FStar_Extraction_ML_Syntax.with_ty_loc t' _0_604
                              _0_603
                             in
                          (_0_605, f, t'))))
       | FStar_Syntax_Syntax.Tm_match (scrutinee,pats) ->
           let uu____5359 = term_as_mlexpr g scrutinee  in
           (match uu____5359 with
            | (e,f_e,t_e) ->
                let uu____5369 = check_pats_for_ite pats  in
                (match uu____5369 with
                 | (b,then_e,else_e) ->
                     let no_lift x t = x  in
                     if b
                     then
                       (match (then_e, else_e) with
                        | (Some then_e,Some else_e) ->
                            let uu____5404 = term_as_mlexpr g then_e  in
                            (match uu____5404 with
                             | (then_mle,f_then,t_then) ->
                                 let uu____5414 = term_as_mlexpr g else_e  in
                                 (match uu____5414 with
                                  | (else_mle,f_else,t_else) ->
                                      let uu____5424 =
                                        let uu____5431 =
                                          type_leq g t_then t_else  in
                                        if uu____5431
                                        then (t_else, no_lift)
                                        else
                                          (let uu____5443 =
                                             type_leq g t_else t_then  in
                                           if uu____5443
                                           then (t_then, no_lift)
                                           else
                                             (FStar_Extraction_ML_Syntax.MLTY_Top,
                                               FStar_Extraction_ML_Syntax.apply_obj_repr))
                                         in
                                      (match uu____5424 with
                                       | (t_branch,maybe_lift) ->
                                           let _0_610 =
                                             let _0_608 =
                                               FStar_Extraction_ML_Syntax.MLE_If
                                                 (let _0_607 =
                                                    maybe_lift then_mle
                                                      t_then
                                                     in
                                                  let _0_606 =
                                                    Some
                                                      (maybe_lift else_mle
                                                         t_else)
                                                     in
                                                  (e, _0_607, _0_606))
                                                in
                                             FStar_All.pipe_left
                                               (FStar_Extraction_ML_Syntax.with_ty
                                                  t_branch) _0_608
                                              in
                                           let _0_609 =
                                             FStar_Extraction_ML_Util.join
                                               then_e.FStar_Syntax_Syntax.pos
                                               f_then f_else
                                              in
                                           (_0_610, _0_609, t_branch))))
                        | uu____5473 ->
                            failwith
                              "ITE pats matched but then and else expressions not found?")
                     else
                       (let uu____5482 =
                          FStar_All.pipe_right pats
                            (FStar_Util.fold_map
                               (fun compat  ->
                                  fun br  ->
                                    let uu____5532 =
                                      FStar_Syntax_Subst.open_branch br  in
                                    match uu____5532 with
                                    | (pat,when_opt,branch) ->
                                        let uu____5562 =
                                          extract_pat g pat t_e  in
                                        (match uu____5562 with
                                         | (env,p,pat_t_compat) ->
                                             let uu____5593 =
                                               match when_opt with
                                               | None  ->
                                                   (None,
                                                     FStar_Extraction_ML_Syntax.E_PURE)
                                               | Some w ->
                                                   let uu____5608 =
                                                     term_as_mlexpr env w  in
                                                   (match uu____5608 with
                                                    | (w,f_w,t_w) ->
                                                        let w =
                                                          maybe_coerce env w
                                                            t_w
                                                            FStar_Extraction_ML_Syntax.ml_bool_ty
                                                           in
                                                        ((Some w), f_w))
                                                in
                                             (match uu____5593 with
                                              | (when_opt,f_when) ->
                                                  let uu____5636 =
                                                    term_as_mlexpr env branch
                                                     in
                                                  (match uu____5636 with
                                                   | (mlbranch,f_branch,t_branch)
                                                       ->
                                                       let _0_611 =
                                                         FStar_All.pipe_right
                                                           p
                                                           (FStar_List.map
                                                              (fun uu____5691
                                                                  ->
                                                                 match uu____5691
                                                                 with
                                                                 | (p,wopt)
                                                                    ->
                                                                    let when_clause
                                                                    =
                                                                    FStar_Extraction_ML_Util.conjoin_opt
                                                                    wopt
                                                                    when_opt
                                                                     in
                                                                    (p,
                                                                    (when_clause,
                                                                    f_when),
                                                                    (mlbranch,
                                                                    f_branch,
                                                                    t_branch))))
                                                          in
                                                       ((compat &&
                                                           pat_t_compat),
                                                         _0_611))))) true)
                           in
                        match uu____5482 with
                        | (pat_t_compat,mlbranches) ->
                            let mlbranches = FStar_List.flatten mlbranches
                               in
                            let e =
                              if pat_t_compat
                              then e
                              else
                                (FStar_Extraction_ML_UEnv.debug g
                                   (fun uu____5767  ->
                                      let _0_613 =
                                        FStar_Extraction_ML_Code.string_of_mlexpr
                                          g.FStar_Extraction_ML_UEnv.currentModule
                                          e
                                         in
                                      let _0_612 =
                                        FStar_Extraction_ML_Code.string_of_mlty
                                          g.FStar_Extraction_ML_UEnv.currentModule
                                          t_e
                                         in
                                      FStar_Util.print2
                                        "Coercing scrutinee %s from type %s because pattern type is incompatible\n"
                                        _0_613 _0_612);
                                 FStar_All.pipe_left
                                   (FStar_Extraction_ML_Syntax.with_ty t_e)
                                   (FStar_Extraction_ML_Syntax.MLE_Coerce
                                      (e, t_e,
                                        FStar_Extraction_ML_Syntax.MLTY_Top)))
                               in
                            (match mlbranches with
                             | [] ->
                                 let uu____5780 =
                                   let _0_615 =
                                     let _0_614 =
                                       FStar_Syntax_Syntax.lid_as_fv
                                         FStar_Syntax_Const.failwith_lid
                                         FStar_Syntax_Syntax.Delta_constant
                                         None
                                        in
                                     FStar_Extraction_ML_UEnv.lookup_fv g
                                       _0_614
                                      in
                                   FStar_All.pipe_left FStar_Util.right
                                     _0_615
                                    in
                                 (match uu____5780 with
                                  | (fw,uu____5803,uu____5804) ->
                                      let _0_619 =
                                        let _0_618 =
                                          FStar_Extraction_ML_Syntax.MLE_App
                                            (let _0_617 =
                                               let _0_616 =
                                                 FStar_All.pipe_left
                                                   (FStar_Extraction_ML_Syntax.with_ty
                                                      FStar_Extraction_ML_Syntax.ml_string_ty)
                                                   (FStar_Extraction_ML_Syntax.MLE_Const
                                                      (FStar_Extraction_ML_Syntax.MLC_String
                                                         "unreachable"))
                                                  in
                                               [_0_616]  in
                                             (fw, _0_617))
                                           in
                                        FStar_All.pipe_left
                                          (FStar_Extraction_ML_Syntax.with_ty
                                             FStar_Extraction_ML_Syntax.ml_unit_ty)
                                          _0_618
                                         in
                                      (_0_619,
                                        FStar_Extraction_ML_Syntax.E_PURE,
                                        FStar_Extraction_ML_Syntax.ml_unit_ty))
                             | (uu____5806,uu____5807,(uu____5808,f_first,t_first))::rest
                                 ->
                                 let uu____5840 =
                                   FStar_List.fold_left
                                     (fun uu____5856  ->
                                        fun uu____5857  ->
                                          match (uu____5856, uu____5857) with
                                          | ((topt,f),(uu____5887,uu____5888,
                                                       (uu____5889,f_branch,t_branch)))
                                              ->
                                              let f =
                                                FStar_Extraction_ML_Util.join
                                                  top.FStar_Syntax_Syntax.pos
                                                  f f_branch
                                                 in
                                              let topt =
                                                match topt with
                                                | None  -> None
                                                | Some t ->
                                                    let uu____5920 =
                                                      type_leq g t t_branch
                                                       in
                                                    if uu____5920
                                                    then Some t_branch
                                                    else
                                                      (let uu____5923 =
                                                         type_leq g t_branch
                                                           t
                                                          in
                                                       if uu____5923
                                                       then Some t
                                                       else None)
                                                 in
                                              (topt, f))
                                     ((Some t_first), f_first) rest
                                    in
                                 (match uu____5840 with
                                  | (topt,f_match) ->
                                      let mlbranches =
                                        FStar_All.pipe_right mlbranches
                                          (FStar_List.map
                                             (fun uu____5969  ->
                                                match uu____5969 with
                                                | (p,(wopt,uu____5985),
                                                   (b,uu____5987,t)) ->
                                                    let b =
                                                      match topt with
                                                      | None  ->
                                                          FStar_Extraction_ML_Syntax.apply_obj_repr
                                                            b t
                                                      | Some uu____5998 -> b
                                                       in
                                                    (p, wopt, b)))
                                         in
                                      let t_match =
                                        match topt with
                                        | None  ->
                                            FStar_Extraction_ML_Syntax.MLTY_Top
                                        | Some t -> t  in
                                      let _0_620 =
                                        FStar_All.pipe_left
                                          (FStar_Extraction_ML_Syntax.with_ty
                                             t_match)
                                          (FStar_Extraction_ML_Syntax.MLE_Match
                                             (e, mlbranches))
                                         in
                                      (_0_620, f_match, t_match)))))))

let fresh : Prims.string -> (Prims.string * Prims.int) =
  let c = FStar_Util.mk_ref (Prims.parse_int "0")  in
  fun x  -> FStar_Util.incr c; (let _0_621 = FStar_ST.read c  in (x, _0_621)) 
let ind_discriminator_body :
  FStar_Extraction_ML_UEnv.env ->
    FStar_Ident.lident ->
      FStar_Ident.lident -> FStar_Extraction_ML_Syntax.mlmodule1
  =
  fun env  ->
    fun discName  ->
      fun constrName  ->
        let uu____6030 =
          FStar_TypeChecker_Env.lookup_lid env.FStar_Extraction_ML_UEnv.tcenv
            discName
           in
        match uu____6030 with
        | (uu____6033,fstar_disc_type) ->
            let wildcards =
              let uu____6041 =
                (FStar_Syntax_Subst.compress fstar_disc_type).FStar_Syntax_Syntax.n
                 in
              match uu____6041 with
              | FStar_Syntax_Syntax.Tm_arrow (binders,uu____6048) ->
                  let _0_623 =
                    FStar_All.pipe_right binders
                      (FStar_List.filter
                         (fun uu___138_6078  ->
                            match uu___138_6078 with
                            | (uu____6082,Some (FStar_Syntax_Syntax.Implicit
                               uu____6083)) -> true
                            | uu____6085 -> false))
                     in
                  FStar_All.pipe_right _0_623
                    (FStar_List.map
                       (fun uu____6096  ->
                          let _0_622 = fresh "_"  in
                          (_0_622, FStar_Extraction_ML_Syntax.MLTY_Top)))
              | uu____6102 -> failwith "Discriminator must be a function"  in
            let mlid = fresh "_discr_"  in
            let targ = FStar_Extraction_ML_Syntax.MLTY_Top  in
            let disc_ty = FStar_Extraction_ML_Syntax.MLTY_Top  in
            let discrBody =
              let _0_637 =
                FStar_Extraction_ML_Syntax.MLE_Fun
                  (let _0_636 =
                     let _0_635 =
                       FStar_Extraction_ML_Syntax.MLE_Match
                         (let _0_634 =
                            let _0_625 =
                              FStar_Extraction_ML_Syntax.MLE_Name
                                (let _0_624 =
                                   FStar_Extraction_ML_Syntax.idsym mlid  in
                                 ([], _0_624))
                               in
                            FStar_All.pipe_left
                              (FStar_Extraction_ML_Syntax.with_ty targ)
                              _0_625
                             in
                          let _0_633 =
                            let _0_632 =
                              let _0_628 =
                                FStar_Extraction_ML_Syntax.MLP_CTor
                                  (let _0_626 =
                                     FStar_Extraction_ML_Syntax.mlpath_of_lident
                                       constrName
                                      in
                                   (_0_626,
                                     [FStar_Extraction_ML_Syntax.MLP_Wild]))
                                 in
                              let _0_627 =
                                FStar_All.pipe_left
                                  (FStar_Extraction_ML_Syntax.with_ty
                                     FStar_Extraction_ML_Syntax.ml_bool_ty)
                                  (FStar_Extraction_ML_Syntax.MLE_Const
                                     (FStar_Extraction_ML_Syntax.MLC_Bool
                                        true))
                                 in
                              (_0_628, None, _0_627)  in
                            let _0_631 =
                              let _0_630 =
                                let _0_629 =
                                  FStar_All.pipe_left
                                    (FStar_Extraction_ML_Syntax.with_ty
                                       FStar_Extraction_ML_Syntax.ml_bool_ty)
                                    (FStar_Extraction_ML_Syntax.MLE_Const
                                       (FStar_Extraction_ML_Syntax.MLC_Bool
                                          false))
                                   in
                                (FStar_Extraction_ML_Syntax.MLP_Wild, None,
                                  _0_629)
                                 in
                              [_0_630]  in
                            _0_632 :: _0_631  in
                          (_0_634, _0_633))
                        in
                     FStar_All.pipe_left
                       (FStar_Extraction_ML_Syntax.with_ty
                          FStar_Extraction_ML_Syntax.ml_bool_ty) _0_635
                      in
                   ((FStar_List.append wildcards [(mlid, targ)]), _0_636))
                 in
              FStar_All.pipe_left
                (FStar_Extraction_ML_Syntax.with_ty disc_ty) _0_637
               in
            FStar_Extraction_ML_Syntax.MLM_Let
              (let _0_640 =
                 let _0_639 =
                   let _0_638 =
                     FStar_Extraction_ML_UEnv.convIdent
                       discName.FStar_Ident.ident
                      in
                   {
                     FStar_Extraction_ML_Syntax.mllb_name = _0_638;
                     FStar_Extraction_ML_Syntax.mllb_tysc = None;
                     FStar_Extraction_ML_Syntax.mllb_add_unit = false;
                     FStar_Extraction_ML_Syntax.mllb_def = discrBody;
                     FStar_Extraction_ML_Syntax.print_typ = false
                   }  in
                 [_0_639]  in
               (FStar_Extraction_ML_Syntax.NonRec, [], _0_640))
  