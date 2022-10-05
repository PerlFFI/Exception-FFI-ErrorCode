# Exception::FFI::ErrorCode ![static](https://github.com/PerlFFI/Exception-FFI-ErrorCode/workflows/static/badge.svg) ![linux](https://github.com/PerlFFI/Exception-FFI-ErrorCode/workflows/linux/badge.svg)

Exception class based on integer error codes common in C code

# SYNOPSIS

Throwing:

```perl
# realish world example for use with libcurl
package CurlError {
  use Exception::FFI::ErrorCode
    code => {
      CURLE_OK                   => 0,
      CURLE_UNKNOWN_OPTION       => 48
      ...
    };
  $ffi->attach( [ curl_easy_strerror => strerror ] => ['enum'] => 'string' => sub {
    my($xsub, $self, $code) = @_;
    $xsub->($code);
  });
}

# foo is an unknown option, so this will return 48
my $code = $curl->setopt( "foo" => "bar" );
# throw as an exception
CurlError->throw( code => $code ) if $code != CurlError::CURLE_OK;
```

Defining error class without a strerror

```perl
package CurlError {
  use Exception::FFI::ErrorCode
    code => {
      CURLE_OK                   => [ 0,  'no error'                        ],
      CURLE_UNKNOWN_OPTION       => [ 48, 'unknown option passed to setopt' ],
      ...
    };
}
...
```

Catching:

```perl
eval {
  might_die;
};
if(my $ex = $@) {
  if($ex isa 'CurlError') {
    my $package  = $ex->package;   # the package where thrown
    my $filename = $ex->filename;  # the filename where thrown
    my $line     = $ex->line;      # the linenumber where thrown
    my $code     = $ex->code;      # the error code
    my $human    = $ex->strerror;  # human readable error
    my $diag     = $ex->as_string; # human readable error at filename.pl line xxx
    my $diag     = "$ex";          # same as $ex->as_string

    if($ex->code == CurlError::UNKNOWN_OPTION) {
      # handle the unknown option variant of this error
    }
  }
}
```

# DESCRIPTION

A common pattern in C libraries is to return an integer error code to classify an error.
When translating those APIs to Perl you often want to instead throw an exception.  This
class provides an interface for building exception classes that help with that pattern.

For APIs that provide a `strerror` or similar function that converts the error code into
a human readable diagnostic, you can simply attach it.  If not you can provide human
readable diagnostics for each error code using an array reference, as shown above.

The base class for your exception class will be set to
[Exception::FFI::ErrorCode::Base](#exception-ffi-errorcode-base).  The base class
handles determining the location of where the exception was thrown and will stringify
in a way to look like a regular Perl string exception with the filename and line number
you would expect.

# METHODS

## import

```perl
use Exception::FFI::ErrorCode
  %options;
```

The `import` method will set the base class, and set up any specific error codes.
Options include:

- class

    The exception class.  If not provided this will be determined using `caller`.

- codes

    The error codes.  This is a hash reference.  The keys are the constant names, in C and
    Perl these are usually all upper case like `FOO_BAD_FILENAME`.  The values can be either
    an integer constant, or an array reference with the integer constant and human readable
    diagnostic.  The former is intended for when there is a `strerror` type function that
    will convert the error code into a diagnostic for you. 

- const\_class

    Where to put the constants.  If not provided, these will be be the same as `class`.

# Exception::FFI::ErrorCode::Base

The base class uses [Class::Tiny](https://metacpan.org/pod/Class::Tiny), so feel free to add additional attributes.
The base class provides these attributes and methods:

## throw

```perl
Exception::FFI::ErrorCode::Base->throw( code => $code );
```

Throws the exception with the given code.

## strerror

```perl
my $string = $ex->strerror;
```

Returns a human readable message for the exception.  If available this should be overridden
by attaching the appropriate C function.

## as\_string

```perl
my $string = $ex->as_string;
my $string = "$ex";
```

Returns a human readable diagnostic.  This is in the form of a familiar Perl warning or
string exception, including the filename and line number where the exception was thrown.
If you stringify the exception it will use this method.

## package

```perl
my $package = $ex->package;
```

The package where the exception happened.

## filename

```perl
my $filename = $ex->filename;
```

The filename where the exception happened.

## line

```perl
my $line = $ex->line;
```

The line number where the exception happened.

## code

```perl
my $code = $ex->code;
```

The integer error code.

## SEE ALSO

- [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus)
- [Exception::Class](https://metacpan.org/pod/Exception::Class)
- [Class:Tiny](Class:Tiny)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
