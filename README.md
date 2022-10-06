# Exception::FFI::ErrorCode ![static](https://github.com/PerlFFI/Exception-FFI-ErrorCode/workflows/static/badge.svg) ![linux](https://github.com/PerlFFI/Exception-FFI-ErrorCode/workflows/linux/badge.svg)

Exception class based on integer error codes common in C code

# SYNOPSIS

Throwing:

```perl
# realish world example for use with libcurl
package Curl::Error {
  use Exception::FFI::ErrorCode
    code => {
      CURLE_OK                   => 0,
      CURLE_UNKNOWN_OPTION       => 48
      ...
    };
  $ffi->attach( [ curl_easy_strerror => strerror ] => ['enum'] => 'string' => sub {
    my($xsub, $self) = @_;
    $xsub->($self->code);
  });
}

# foo is an unknown option, so this will return 48
my $code = $curl->setopt( "foo" => "bar" );
# throw as an exception
Curl::Error->throw( code => $code ) if $code != Curl::Error::CURLE_OK;
```

Defining error class without a strerror

```perl
package Curl::<Error {
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
try {
  might_die;
}
catch ($ex) {
  if($ex isa Curl::Error) {
    my $package  = $ex->package;   # the package where thrown
    my $filename = $ex->filename;  # the filename where thrown
    my $line     = $ex->line;      # the linenumber where thrown
    my $code     = $ex->code;      # the error code
    my $human    = $ex->strerror;  # human readable error
    my $diag     = $ex->as_string; # human readable error at filename.pl line xxx
    my $diag     = "$ex";          # same as $ex->as_string

    if($ex->code == Curl::Error::UNKNOWN_OPTION) {
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

This class will attempt to detect if [Carp::Always](https://metacpan.org/pod/Carp::Always) is running and produce a long message
when stringified, as it already does for regular string exceptions.  By default it will
**only** do this if [Carp::Always](https://metacpan.org/pod/Carp::Always) is running when this module is loaded.  Since
typically [Carp::Always](https://metacpan.org/pod/Carp::Always) is loaded via the command line `-MCarp::Always` or via
`PERL5OPT` environment variable this should cover all of the typical use cases, but if
for some reason [Carp::Always](https://metacpan.org/pod/Carp::Always) does get loaded after this module, you can force
redetection by calling the [detect method](#detect).

# METHODS

## detect

```
Exception::FFI::ErrorCode->detect;
```

This will redetect if [Carp::Always](https://metacpan.org/pod/Carp::Always) has been loaded yet.  You do not need to call this
method if [Carp::Always](https://metacpan.org/pod/Carp::Always) has been enabled or disabled (we check for that when the
exception is thrown and stringified), just if the module has been loaded.

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

Throws the exception with the given code.  Obviously you would throw the subclass, not the
base class.

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
If you stringify the exception it will use this method, adding a new line.

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

# CAVEATS

The [Carp::Always](https://metacpan.org/pod/Carp::Always) detection is pretty solid, but if [Carp::Always](https://metacpan.org/pod/Carp::Always) is off when the
exception is thrown but on when it is stringified then strange things might happen.

# SEE ALSO

- [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus)
- [Exception::Class](https://metacpan.org/pod/Exception::Class)
- [Class:Tiny](Class:Tiny)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
