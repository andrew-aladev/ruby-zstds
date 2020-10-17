// Ruby bindings for zstd library.
// Copyright (c) 2019 AUTHORS, MIT License.

#if !defined(ZSTDS_EXT_GVL_H)
#define ZSTDS_EXT_GVL_H

#ifdef HAVE_RB_THREAD_CALL_WITHOUT_GVL

#include "ruby/thread.h"

#define ZSTDS_EXT_GVL_WRAP(gvl, function, data)                            \
  if (gvl) {                                                               \
    function((void*) data);                                                \
  } else {                                                                 \
    rb_thread_call_without_gvl(function, (void*) data, RUBY_UBF_IO, NULL); \
  }

#else

#define ZSTDS_EXT_GVL_WRAP(_gvl, function, data) function((void*) data);

#endif

#endif // ZSTDS_EXT_GVL_H
