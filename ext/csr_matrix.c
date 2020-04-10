#include <ruby.h>
#include "extconf.h"
#include <stdlib.h>
#include <stdio.h>

typedef struct csr_matrix
{
    int m;
    int n;
    int nnz;
    float *values;
    int *col_index;
    int *row_index;
} CSRMatrix;

void csr_matrix_free(void *mat)
{
    CSRMatrix *csr = (CSRMatrix *)mat;

    if (csr->values)
    {
        free(csr->values);
    }

    if (csr->row_index)
    {
        free(csr->row_index);
    }

    if (csr->col_index)
    {
        free(csr->col_index);
    }

    free(mat);
}

size_t csr_matrix_memsize(const void *ptr)
{
    const CSRMatrix *csr = (const CSRMatrix *)ptr;
    return sizeof(csr);
}

static const rb_data_type_t csr_matrix_type = {
    "SpatialStats::Weights::CSRMatrix",
    {NULL, csr_matrix_free, csr_matrix_memsize},
    0,
    0,
    RUBY_TYPED_FREE_IMMEDIATELY};

VALUE csr_matrix_alloc(VALUE self)
{
    CSRMatrix *csr = malloc(sizeof(CSRMatrix));
    return TypedData_Wrap_Struct(self, &csr_matrix_type, csr);
}

VALUE csr_matrix_p_nnz(VALUE self)
{
    CSRMatrix *csr;
    TypedData_Get_Struct(self, CSRMatrix, &csr_matrix_type, csr);
    rb_p(INT2NUM(csr->nnz));
    return Qnil;
}

VALUE csr_matrix_mulvec(VALUE self, VALUE vec)
{
    CSRMatrix *csr;
    VALUE result;

    int i;
    int jj;
    float tmp;

    TypedData_Get_Struct(self, CSRMatrix, &csr_matrix_type, csr);

    if (rb_array_len(vec) != csr->n)
    {
        rb_raise(rb_eArgError, "Dimension Mismatch CSRMatrix.n != vec.size");
    }

    result = rb_ary_new_capa(csr->m);

    // float *vals = (float *)DATA_PTR(result);

    for (i = 0; i < csr->m; i++)
    {
        tmp = 0;
        for (jj = csr->row_index[i]; jj < csr->row_index[i + 1]; jj++)
        {
            tmp += csr->values[jj] * NUM2DBL(rb_ary_entry(vec, csr->col_index[jj]));
        }
        rb_ary_store(result, i, DBL2NUM(tmp));
    }

    return result;
}

void mat_to_sparse(CSRMatrix *csr, VALUE data, VALUE num_rows, VALUE num_cols)
{
    // first get count of nnz values in data
    int nnz = 0;
    int m = NUM2INT(num_rows);
    int n = NUM2INT(num_cols);

    float *values;
    int *col_index;
    int *row_index;

    int nz_idx;
    float entry;

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

    values = malloc(sizeof(float) * nnz);
    col_index = malloc(sizeof(int) * nnz);
    row_index = malloc(sizeof(int) * (m + 1));

    nz_idx = 0;
    for (i = 0; i < m; i++)
    {
        row_index[i] = nz_idx;
        for (j = 0; j < n; j++)
        {
            index = i * n + j;
            entry = NUM2DBL(rb_ary_entry(data, index));
            if (entry != 0)
            {
                values[nz_idx] = entry;
                col_index[nz_idx] = j;
                nz_idx++;
            }
        }
    }
    row_index[m] = nnz;

    csr->m = m;
    csr->n = n;
    csr->nnz = nnz;
    csr->values = values;
    csr->col_index = col_index;
    csr->row_index = row_index;
}

VALUE csr_matrix_initialize(VALUE self, VALUE data, VALUE num_rows, VALUE num_cols)
{

    CSRMatrix *csr;
    TypedData_Get_Struct(self, CSRMatrix, &csr_matrix_type, csr);
    csr->values = NULL;
    csr->col_index = NULL;
    csr->row_index = NULL;

    Check_Type(data, T_ARRAY);
    Check_Type(num_rows, T_FIXNUM);
    Check_Type(num_cols, T_FIXNUM);

    // check dimensions are correct
    if (NUM2INT(num_rows) * NUM2INT(num_cols) != rb_array_len(data))
    {
        rb_raise(rb_eArgError, "n_rows * n_cols != data.size, check your dimensions");
    }

    mat_to_sparse(csr, data, num_rows, num_cols);

    rb_iv_set(self, "@m", num_rows);
    rb_iv_set(self, "@n", num_cols);
    rb_iv_set(self, "@nnz", INT2NUM(csr->nnz));

    return self;
}

void Init_csr_matrix()
{
    VALUE spatial_stats_mod = rb_define_module("SpatialStats");
    VALUE weights_mod = rb_define_module_under(spatial_stats_mod, "Weights");
    VALUE csr_matrix_class = rb_define_class_under(weights_mod, "CSRMatrix", rb_cData);

    rb_define_alloc_func(csr_matrix_class, csr_matrix_alloc);
    rb_define_method(csr_matrix_class, "initialize", csr_matrix_initialize, 3);
    rb_define_method(csr_matrix_class, "p_nnz", csr_matrix_p_nnz, 0);
    rb_define_method(csr_matrix_class, "mulvec", csr_matrix_mulvec, 1);

    rb_define_attr(csr_matrix_class, "m", 1, 0);
    rb_define_attr(csr_matrix_class, "n", 1, 0);
    rb_define_attr(csr_matrix_class, "nnz", 1, 0);
}