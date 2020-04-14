#ifndef CSR_MATRIX
#define CSR_MATRIX

typedef struct csr_matrix
{
    char init;
    int m;
    int n;
    int nnz;
    float *values;
    int *col_index;
    int *row_index;
} csr_matrix;

void csr_matrix_free(void *mat);
size_t csr_matrix_memsize(const void *ptr);

// ruby VALUE for csr_matrix
static const rb_data_type_t csr_matrix_type = {
    "SpatialStats::Weights::CSRMatrix",
    {NULL, csr_matrix_free, csr_matrix_memsize},
    0,
    0,
    RUBY_TYPED_FREE_IMMEDIATELY};

void mat_to_sparse(csr_matrix *csr, VALUE data, VALUE num_rows, VALUE num_cols);
VALUE csr_matrix_alloc(VALUE self);
VALUE csr_matrix_initialize(VALUE self, VALUE data, VALUE num_rows, VALUE num_cols);
VALUE csr_matrix_values(VALUE self);
VALUE csr_matrix_col_index(VALUE self);
VALUE csr_matrix_row_index(VALUE self);
VALUE csr_matrix_mulvec(VALUE self, VALUE vec);
VALUE csr_matrix_coordinates(VALUE self);
#endif