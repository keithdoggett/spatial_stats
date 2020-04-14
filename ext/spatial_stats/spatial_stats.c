#include <ruby.h>
#include "csr_matrix.h"

void Init_spatial_stats()
{
    VALUE spatial_stats_mod = rb_define_module("SpatialStats");
    VALUE weights_mod = rb_define_module_under(spatial_stats_mod, "Weights");
    VALUE csr_matrix_class = rb_define_class_under(weights_mod, "CSRMatrix", rb_cData);

    rb_define_alloc_func(csr_matrix_class, csr_matrix_alloc);
    rb_define_method(csr_matrix_class, "initialize", csr_matrix_initialize, 3);
    rb_define_method(csr_matrix_class, "values", csr_matrix_values, 0);
    rb_define_method(csr_matrix_class, "col_index", csr_matrix_col_index, 0);
    rb_define_method(csr_matrix_class, "row_index", csr_matrix_row_index, 0);
    rb_define_method(csr_matrix_class, "mulvec", csr_matrix_mulvec, 1);
    rb_define_method(csr_matrix_class, "coordinates", csr_matrix_coordinates, 0);

    rb_define_attr(csr_matrix_class, "m", 1, 0);
    rb_define_attr(csr_matrix_class, "n", 1, 0);
    rb_define_attr(csr_matrix_class, "nnz", 1, 0);
}