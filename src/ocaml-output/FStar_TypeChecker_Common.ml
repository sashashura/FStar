open Prims
type rel =
  | EQ 
  | SUB 
  | SUBINV 
let uu___is_EQ : rel -> Prims.bool =
  fun projectee  -> match projectee with | EQ  -> true | uu____4 -> false 
let uu___is_SUB : rel -> Prims.bool =
  fun projectee  -> match projectee with | SUB  -> true | uu____8 -> false 
let uu___is_SUBINV : rel -> Prims.bool =
  fun projectee  ->
    match projectee with | SUBINV  -> true | uu____12 -> false
  
type ('a,'b) problem =
  {
  pid: Prims.int ;
  lhs: 'a ;
  relation: rel ;
  rhs: 'a ;
  element: 'b Prims.option ;
  logical_guard: (FStar_Syntax_Syntax.term * FStar_Syntax_Syntax.term) ;
  scope: FStar_Syntax_Syntax.binders ;
  reason: Prims.string Prims.list ;
  loc: FStar_Range.range ;
  rank: Prims.int Prims.option }
type prob =
  | TProb of (FStar_Syntax_Syntax.typ,FStar_Syntax_Syntax.term) problem 
  | CProb of (FStar_Syntax_Syntax.comp,Prims.unit) problem 
let uu___is_TProb : prob -> Prims.bool =
  fun projectee  ->
    match projectee with | TProb _0 -> true | uu____240 -> false
  
let __proj__TProb__item___0 :
  prob -> (FStar_Syntax_Syntax.typ,FStar_Syntax_Syntax.term) problem =
  fun projectee  -> match projectee with | TProb _0 -> _0 
let uu___is_CProb : prob -> Prims.bool =
  fun projectee  ->
    match projectee with | CProb _0 -> true | uu____260 -> false
  
let __proj__CProb__item___0 :
  prob -> (FStar_Syntax_Syntax.comp,Prims.unit) problem =
  fun projectee  -> match projectee with | CProb _0 -> _0 
type probs = prob Prims.list
type guard_formula =
  | Trivial 
  | NonTrivial of FStar_Syntax_Syntax.formula 
let uu___is_Trivial : guard_formula -> Prims.bool =
  fun projectee  ->
    match projectee with | Trivial  -> true | uu____281 -> false
  
let uu___is_NonTrivial : guard_formula -> Prims.bool =
  fun projectee  ->
    match projectee with | NonTrivial _0 -> true | uu____286 -> false
  
let __proj__NonTrivial__item___0 :
  guard_formula -> FStar_Syntax_Syntax.formula =
  fun projectee  -> match projectee with | NonTrivial _0 -> _0 
type deferred = (Prims.string * prob) Prims.list
type univ_ineq =
  (FStar_Syntax_Syntax.universe * FStar_Syntax_Syntax.universe)
let tconst :
  FStar_Ident.lident ->
    (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
      FStar_Syntax_Syntax.syntax
  =
  fun l  ->
    (FStar_Syntax_Syntax.mk
       (FStar_Syntax_Syntax.Tm_fvar
          (FStar_Syntax_Syntax.lid_as_fv l FStar_Syntax_Syntax.Delta_constant
             None))) (Some (FStar_Syntax_Util.ktype0.FStar_Syntax_Syntax.n))
      FStar_Range.dummyRange
  
let tabbrev :
  FStar_Ident.lident ->
    (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
      FStar_Syntax_Syntax.syntax
  =
  fun l  ->
    (FStar_Syntax_Syntax.mk
       (FStar_Syntax_Syntax.Tm_fvar
          (FStar_Syntax_Syntax.lid_as_fv l
             (FStar_Syntax_Syntax.Delta_defined_at_level
                (Prims.parse_int "1")) None)))
      (Some (FStar_Syntax_Util.ktype0.FStar_Syntax_Syntax.n))
      FStar_Range.dummyRange
  
let t_unit :
  (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
    FStar_Syntax_Syntax.syntax
  = tconst FStar_Syntax_Const.unit_lid 
let t_bool :
  (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
    FStar_Syntax_Syntax.syntax
  = tconst FStar_Syntax_Const.bool_lid 
let t_int :
  (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
    FStar_Syntax_Syntax.syntax
  = tconst FStar_Syntax_Const.int_lid 
let t_string :
  (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
    FStar_Syntax_Syntax.syntax
  = tconst FStar_Syntax_Const.string_lid 
let t_float :
  (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
    FStar_Syntax_Syntax.syntax
  = tconst FStar_Syntax_Const.float_lid 
let t_char :
  (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
    FStar_Syntax_Syntax.syntax
  = tabbrev FStar_Syntax_Const.char_lid 
let t_range :
  (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
    FStar_Syntax_Syntax.syntax
  = tconst FStar_Syntax_Const.range_lid 
let rec delta_depth_greater_than :
  FStar_Syntax_Syntax.delta_depth ->
    FStar_Syntax_Syntax.delta_depth -> Prims.bool
  =
  fun l  ->
    fun m  ->
      match (l, m) with
      | (FStar_Syntax_Syntax.Delta_constant ,uu____345) -> false
      | (FStar_Syntax_Syntax.Delta_equational ,uu____346) -> true
      | (uu____347,FStar_Syntax_Syntax.Delta_equational ) -> false
      | (FStar_Syntax_Syntax.Delta_defined_at_level
         i,FStar_Syntax_Syntax.Delta_defined_at_level j) -> i > j
      | (FStar_Syntax_Syntax.Delta_defined_at_level
         uu____350,FStar_Syntax_Syntax.Delta_constant ) -> true
      | (FStar_Syntax_Syntax.Delta_abstract d,uu____352) ->
          delta_depth_greater_than d m
      | (uu____353,FStar_Syntax_Syntax.Delta_abstract d) ->
          delta_depth_greater_than l d
  
let rec decr_delta_depth :
  FStar_Syntax_Syntax.delta_depth ->
    FStar_Syntax_Syntax.delta_depth Prims.option
  =
  fun uu___93_358  ->
    match uu___93_358 with
    | FStar_Syntax_Syntax.Delta_constant 
      |FStar_Syntax_Syntax.Delta_equational  -> None
    | FStar_Syntax_Syntax.Delta_defined_at_level _0_186 when
        _0_186 = (Prims.parse_int "1") ->
        Some FStar_Syntax_Syntax.Delta_constant
    | FStar_Syntax_Syntax.Delta_defined_at_level i ->
        Some
          (FStar_Syntax_Syntax.Delta_defined_at_level
             (i - (Prims.parse_int "1")))
    | FStar_Syntax_Syntax.Delta_abstract d -> decr_delta_depth d
  
type identifier_info =
  {
  identifier:
    (FStar_Syntax_Syntax.bv,FStar_Syntax_Syntax.fv) FStar_Util.either ;
  identifier_ty: FStar_Syntax_Syntax.typ }
let info_as_string : identifier_info -> Prims.string =
  fun info  ->
    let uu____385 =
      match info.identifier with
      | FStar_Util.Inl bv ->
          let _0_188 = FStar_Syntax_Print.bv_to_string bv  in
          let _0_187 = FStar_Syntax_Syntax.range_of_bv bv  in
          (_0_188, _0_187)
      | FStar_Util.Inr fv ->
          let _0_190 =
            FStar_Syntax_Print.lid_to_string
              (FStar_Syntax_Syntax.lid_of_fv fv)
             in
          let _0_189 = FStar_Syntax_Syntax.range_of_fv fv  in
          (_0_190, _0_189)
       in
    match uu____385 with
    | (id_string,range) ->
        let _0_192 = FStar_Syntax_Print.term_to_string info.identifier_ty  in
        let _0_191 = FStar_Range.string_of_range range  in
        FStar_Util.format3 "%s : %s (defined at %s)" id_string _0_192 _0_191
  
let rec insert_col_info col info col_infos =
  match col_infos with
  | [] -> [(col, info)]
  | (c,i)::rest ->
      if col < c
      then (col, info) :: col_infos
      else (let _0_193 = insert_col_info col info rest  in (c, i) :: _0_193)
  
let find_nearest_preceding_col_info col col_infos =
  let rec aux out uu___94_472 =
    match uu___94_472 with
    | [] -> out
    | (c,i)::rest -> if c > col then out else aux (Some i) rest  in
  aux None col_infos 
type col_info = (Prims.int * identifier_info) Prims.list
type row_info = col_info FStar_ST.ref FStar_Util.imap
type file_info = row_info FStar_Util.smap
let mk_info :
  (FStar_Syntax_Syntax.bv,FStar_Syntax_Syntax.fv) FStar_Util.either ->
    FStar_Syntax_Syntax.typ -> identifier_info
  = fun id  -> fun ty  -> { identifier = id; identifier_ty = ty } 
let file_info_table : row_info FStar_Util.smap =
  FStar_Util.smap_create (Prims.parse_int "50") 
let insert_identifier_info :
  (FStar_Syntax_Syntax.bv,FStar_Syntax_Syntax.fv) FStar_Util.either ->
    FStar_Syntax_Syntax.typ -> FStar_Range.range -> Prims.unit
  =
  fun id  ->
    fun ty  ->
      fun range  ->
        let info = mk_info id ty  in
        let fn = FStar_Range.file_of_range range  in
        let start = FStar_Range.start_of_range range  in
        let uu____523 =
          let _0_195 = FStar_Range.line_of_pos start  in
          let _0_194 = FStar_Range.col_of_pos start  in (_0_195, _0_194)  in
        match uu____523 with
        | (row,col) ->
            let uu____528 = FStar_Util.smap_try_find file_info_table fn  in
            (match uu____528 with
             | None  ->
                 let col_info =
                   FStar_Util.mk_ref (insert_col_info col info [])  in
                 let rows = FStar_Util.imap_create (Prims.parse_int "1000")
                    in
                 (FStar_Util.imap_add rows row col_info;
                  FStar_Util.smap_add file_info_table fn rows)
             | Some file_rows ->
                 let uu____559 = FStar_Util.imap_try_find file_rows row  in
                 (match uu____559 with
                  | None  ->
                      let col_info =
                        FStar_Util.mk_ref (insert_col_info col info [])  in
                      FStar_Util.imap_add file_rows row col_info
                  | Some col_infos ->
                      let _0_197 =
                        let _0_196 = FStar_ST.read col_infos  in
                        insert_col_info col info _0_196  in
                      FStar_ST.write col_infos _0_197))
  
let info_at_pos :
  Prims.string -> Prims.int -> Prims.int -> Prims.string Prims.option =
  fun fn  ->
    fun row  ->
      fun col  ->
        let uu____596 = FStar_Util.smap_try_find file_info_table fn  in
        match uu____596 with
        | None  -> None
        | Some rows ->
            let uu____600 = FStar_Util.imap_try_find rows row  in
            (match uu____600 with
             | None  -> None
             | Some cols ->
                 let uu____609 =
                   let _0_198 = FStar_ST.read cols  in
                   find_nearest_preceding_col_info col _0_198  in
                 (match uu____609 with
                  | None  -> None
                  | Some ci -> Some (info_as_string ci)))
  
let insert_bv :
  FStar_Syntax_Syntax.bv -> FStar_Syntax_Syntax.typ -> Prims.unit =
  fun bv  ->
    fun ty  ->
      let _0_199 = FStar_Syntax_Syntax.range_of_bv bv  in
      insert_identifier_info (FStar_Util.Inl bv) ty _0_199
  
let insert_fv :
  FStar_Syntax_Syntax.fv -> FStar_Syntax_Syntax.typ -> Prims.unit =
  fun fv  ->
    fun ty  ->
      let _0_200 = FStar_Syntax_Syntax.range_of_fv fv  in
      insert_identifier_info (FStar_Util.Inr fv) ty _0_200
  