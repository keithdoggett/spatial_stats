#include <ruby.h>
#include "extconf.h"
#include <stdlib.h>
#include <stdio.h>

typedef struct csr_matrix
{
    int m;
    int nnz;
    VALUE *values;
    VALUE *col_index;
    VALUE *row_index;
} CSRMatrix;

CSRMatrix *mat_to_sparse(VALUE data, VALUE num_rows, VALUE num_cols)
{
    // first get count of nnz values in data
    int nnz = 0;
    int m = NUM2INT(num_rows);
    int n = NUM2INT(num_cols);

    int i;
    int j;
    int index;
    for (i = 0; i < m; i++)
    {
        for (j = 0; j < n; j++)
        {
            index = i * n + j;
            if (NUM2DBL(rb_ary_entry(data, index)) != 0)
            {
                nnz++;
            }
        }
    }

    VALUE *values = malloc(sizeof(VALUE) * nnz);
    VALUE *col_index = malloc(sizeof(VALUE) * nnz);
    VALUE *row_index = malloc(sizeof(VALUE) * (m + 1));

    int nz_idx = 0;
    float entry;
    for (i = 0; i < m; i++)
    {
        row_index[i] = INT2NUM(nz_idx);
        for (j = 0; j < n; j++)
        {
            index = i * n + j;
            entry = NUM2DBL(rb_ary_entry(data, index));
            if (entry != 0)
            {
                values[nz_idx] = rb_ary_entry(data, index);
                col_index[nz_idx] = INT2NUM(j);
                nz_idx++;
            }
        }
    }
    row_index[m] = INT2NUM(nnz);

    CSRMatrix *csr = malloc(sizeof(CSRMatrix));
    csr->m = m;
    csr->nnz = nnz;
    csr->values = values;
    csr->col_index = col_index;
    csr->row_index = row_index;
    return csr;
}

VALUE csr_matrix_initialize(VALUE self, VALUE data, VALUE num_rows, VALUE num_cols)
{
    Check_Type(data, T_ARRAY);
    Check_Type(num_rows, T_FIXNUM);
    Check_Type(num_cols, T_FIXNUM);

    CSRMatrix *csr = mat_to_sparse(data, num_rows, num_cols);

    VALUE values = rb_ary_new_from_values(csr->nnz, csr->values);
    VALUE col_index = rb_ary_new_from_values(csr->nnz, csr->col_index);
    VALUE row_index = rb_ary_new_from_values(csr->m + 1, csr->row_index);

    rb_iv_set(self, "@x", data);
    rb_iv_set(self, "@m", num_rows);
    rb_iv_set(self, "@n", num_cols);
    rb_iv_set(self, "@values", values);
    rb_iv_set(self, "@col_index", col_index);
    rb_iv_set(self, "@row_index", row_index);

    return self;
}

void Init_csr_matrix()
{
    VALUE spatial_stats_mod = rb_define_module("SpatialStats");
    VALUE weights_mod = rb_define_module_under(spatial_stats_mod, "Weights");
    VALUE csr_matrix_class = rb_define_class_under(weights_mod, "CSRMatrix", rb_cObject);

    rb_define_method(csr_matrix_class, "initialize", csr_matrix_initialize, 3);

    rb_define_attr(csr_matrix_class, "x", 1, 0);
    rb_define_attr(csr_matrix_class, "m", 1, 0);
    rb_define_attr(csr_matrix_class, "n", 1, 0);
    rb_define_attr(csr_matrix_class, "values", 1, 0);
    rb_define_attr(csr_matrix_class, "col_index", 1, 0);
    rb_define_attr(csr_matrix_class, "row_index", 1, 0);
}