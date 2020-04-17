#include <ruby.h>
#include <stdlib.h>
#include <stdio.h>
#include "csr_matrix.h"

void csr_matrix_free(void *mat)
{
    csr_matrix *csr = (csr_matrix *)mat;

    if (csr->init == 1)
    {
        free(csr->values);
        free(csr->col_index);
        free(csr->row_index);
    }
    free(mat);
}

size_t csr_matrix_memsize(const void *ptr)
{
    const csr_matrix *csr = (const csr_matrix *)ptr;
    return sizeof(*csr);
}

VALUE csr_matrix_alloc(VALUE self)
{
    csr_matrix *csr = malloc(sizeof(csr_matrix));
    return TypedData_Wrap_Struct(self, &csr_matrix_type, csr);
}

void mat_to_sparse(csr_matrix *csr, VALUE data, VALUE num_rows, VALUE num_cols)
{
    int nnz = 0;
    int m = NUM2INT(num_rows);
    int n = NUM2INT(num_cols);

    double *values;
    int *col_index;
    int *row_index;

    int nz_idx;
    double entry;

    int i;
    int j;
    int index;

    // first get number non zero count so we can alloc values and col_index
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

    values = malloc(sizeof(double) * nnz);
    col_index = malloc(sizeof(int) * nnz);
    row_index = malloc(sizeof(int) * (m + 1));

    // for every non-zero, record value, column and then get values per row
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
    csr->init = 1;
}

/**
 *  A new instance of CSRMatrix.
 *  Uses a 1-D representation of a 2-D array as input.
 *  @example
 *      dummy_data = [
 *                      [0, 1, 2]
 *                      [3, 4, 5],
 *                      [6, 7, 8]   
 *                   ]
 *      num_rows = 3
 *      num_cols = 3
 *      data = dummy_data.flatten
 *      # => [0, 1, 2, 3, 4, 5, 6, 7, 8]
 *      
 *      csr = CSRMatrix.new(data, num_rows, num_cols)
 * 
 *  @param [Array] data in 1-D format
 *  @param [Integer] num_rows in the 2-D representation
 *  @param [Integer] num_cols in the 2-D representation
 *  
 *  @return [CSRMatrix]
 */
VALUE csr_matrix_initialize(VALUE self, VALUE data, VALUE num_rows, VALUE num_cols)
{

    csr_matrix *csr;
    TypedData_Get_Struct(self, csr_matrix, &csr_matrix_type, csr);
    csr->init = 0;

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

/**
 *  Non-zero values in the matrix.
 *  
 *  @return [Array] of the non-zero values.
 */
VALUE csr_matrix_values(VALUE self)
{
    csr_matrix *csr;
    VALUE result;

    int i;

    TypedData_Get_Struct(self, csr_matrix, &csr_matrix_type, csr);

    result = rb_ary_new_capa(csr->nnz);
    for (i = 0; i < csr->nnz; i++)
    {
        rb_ary_store(result, i, DBL2NUM(csr->values[i]));
    }

    return result;
}

/**
 *  Column indices of the non-zero values.
 *  
 *  @return [Array] of the column indices.
 */
VALUE csr_matrix_col_index(VALUE self)
{
    csr_matrix *csr;
    VALUE result;

    int i;

    TypedData_Get_Struct(self, csr_matrix, &csr_matrix_type, csr);

    result = rb_ary_new_capa(csr->nnz);
    for (i = 0; i < csr->nnz; i++)
    {
        rb_ary_store(result, i, INT2NUM(csr->col_index[i]));
    }

    return result;
}

/**
 *  Row indices of the non-zero values. Represents the start index
 *  of values in a row. For example [0,2,3] would represent a matrix
 *  with 2 rows, the first containing 2 non-zero values and the second
 *  containing 1. Length is num_rows + 1.
 * 
 *  Used for row slicing operations.
 *  
 *  @return [Array] of the row indices.
 */
VALUE csr_matrix_row_index(VALUE self)
{
    csr_matrix *csr;
    VALUE result;

    int i;

    TypedData_Get_Struct(self, csr_matrix, &csr_matrix_type, csr);

    result = rb_ary_new_capa(csr->m + 1);
    for (i = 0; i <= csr->m; i++)
    {
        rb_ary_store(result, i, INT2NUM(csr->row_index[i]));
    }

    return result;
}

/**
 *  Multiply matrix by the input vector.
 *  
 *  @see https://github.com/scipy/scipy/blob/53fac7a1d8a81d48be757632ad285b6fc76529ba/scipy/sparse/sparsetools/csr.h#L1120
 *  
 *  @param [Array] vec of length n. 
 * 
 *  @return [Array] of the result of the multiplication.
 */
VALUE csr_matrix_mulvec(VALUE self, VALUE vec)
{
    csr_matrix *csr;
    VALUE result;

    int i;
    int jj;
    double tmp;

    Check_Type(vec, T_ARRAY);

    TypedData_Get_Struct(self, csr_matrix, &csr_matrix_type, csr);

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

/**
 *  Compute the dot product of the given row with the input vector.
 *  Equivalent to +mulvec(vec)[row]+.
 *  
 *  @param [Array] vec of length n. 
 *  @param [Integer] row of the dot product.
 * 
 *  @return [Float] of the result of the dot product.
 */
VALUE csr_matrix_dot_row(VALUE self, VALUE vec, VALUE row)
{
    csr_matrix *csr;
    VALUE result;

    int i;
    int jj;
    double tmp;

    Check_Type(vec, T_ARRAY);
    Check_Type(row, T_FIXNUM);

    TypedData_Get_Struct(self, csr_matrix, &csr_matrix_type, csr);

    if (rb_array_len(vec) != csr->n)
    {
        rb_raise(rb_eArgError, "Dimension Mismatch CSRMatrix.n != vec.size");
    }

    i = NUM2INT(row);
    if (!(i >= 0 && i < csr->m))
    {
        rb_raise(rb_eArgError, "Index Error row_idx >= m or idx < 0");
    }

    tmp = 0;
    for (jj = csr->row_index[i]; jj < csr->row_index[i + 1]; jj++)
    {
        tmp += csr->values[jj] * NUM2DBL(rb_ary_entry(vec, csr->col_index[jj]));
    }

    result = DBL2NUM(tmp);
    return result;
}

/** 
 *  A hash representation of the matrix with coordinates as keys.
 *  @example
 *      data = [
 *              [0, 1, 0]
 *              [0, 0, 0],
 *              [1, 0, 1]   
 *             ]
 *      num_rows = 3
 *      num_cols = 3
 *      data = data.flatten!
 *      csr = CSRMatrix.new(data, num_rows, num_cols)
 *  
 *      csr.coordinates
 *      # => {
 *              [0,1] => 1,
 *              [2,0] => 1,
 *              [2,2] => 1
 *           }
 *  
 *  @return [Hash]
 */
VALUE csr_matrix_coordinates(VALUE self)
{
    csr_matrix *csr;
    VALUE result;

    int i;
    int k;

    VALUE key;
    VALUE val;
    int row_end;

    TypedData_Get_Struct(self, csr_matrix, &csr_matrix_type, csr);

    result = rb_hash_new();

    // iterate through every value in the matrix and assign it's coordinates
    // [x,y] as the key to the hash, with the value as the value.
    // Use i to keep track of what row we are on.
    i = 0;
    row_end = csr->row_index[1];
    for (k = 0; k < csr->nnz; k++)
    {
        if (k == row_end)
        {
            i++;
            row_end = csr->row_index[i + 1];
        }

        // store i,j coordinates j is col_index[k]
        key = rb_ary_new_capa(2);
        rb_ary_store(key, 0, INT2NUM(i));
        rb_ary_store(key, 1, INT2NUM(csr->col_index[k]));

        val = DBL2NUM(csr->values[k]);

        rb_hash_aset(result, key, val);
    }

    return result;
}