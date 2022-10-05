package Exception::FFI::ErrorCode {

  use warnings;
  use 5.020;
  use constant 1.32 ();
  use experimental qw( signatures postderef );
  use Ref::Util qw( is_plain_arrayref );

  # ABSTRACT: Exception class based on integer error codes common in C code
  # VERSION

=head1 SYNOPSIS

Throwing:

 # realish world example for use with libcurl
 package Curl::Error {
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
 Curl::Error->throw( code => $code ) if $code != Curl::Error::CURLE_OK;

Defining error class without a strerror

 package Curl::<Error {
   use Exception::FFI::ErrorCode
     code => {
       CURLE_OK                   => [ 0,  'no error'                        ],
       CURLE_UNKNOWN_OPTION       => [ 48, 'unknown option passed to setopt' ],
       ...
     };
 }
 ...

Catching:

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

=head1 DESCRIPTION

A common pattern in C libraries is to return an integer error code to classify an error.
When translating those APIs to Perl you often want to instead throw an exception.  This
class provides an interface for building exception classes that help with that pattern.

For APIs that provide a C<strerror> or similar function that converts the error code into
a human readable diagnostic, you can simply attach it.  If not you can provide human
readable diagnostics for each error code using an array reference, as shown above.

The base class for your exception class will be set to
L<Exception::FFI::ErrorCode::Base|/Exception::FFI::ErrorCode::Base>.  The base class
handles determining the location of where the exception was thrown and will stringify
in a way to look like a regular Perl string exception with the filename and line number
you would expect.

=head1 METHODS

=head2 import

 use Exception::FFI::ErrorCode
   %options;

The C<import> method will set the base class, and set up any specific error codes.
Options include:

=over 4

=item class

The exception class.  If not provided this will be determined using C<caller>.

=item codes

The error codes.  This is a hash reference.  The keys are the constant names, in C and
Perl these are usually all upper case like C<FOO_BAD_FILENAME>.  The values can be either
an integer constant, or an array reference with the integer constant and human readable
diagnostic.  The former is intended for when there is a C<strerror> type function that
will convert the error code into a diagnostic for you. 

=item const_class

Where to put the constants.  If not provided, these will be be the same as C<class>.

=back

=head1 Exception::FFI::ErrorCode::Base

The base class uses L<Class::Tiny>, so feel free to add additional attributes.
The base class provides these attributes and methods:

=head2 throw

 Exception::FFI::ErrorCode::Base->throw( code => $code );

Throws the exception with the given code.

=head2 strerror

 my $string = $ex->strerror;

Returns a human readable message for the exception.  If available this should be overridden
by attaching the appropriate C function.

=head2 as_string

 my $string = $ex->as_string;
 my $string = "$ex";

Returns a human readable diagnostic.  This is in the form of a familiar Perl warning or
string exception, including the filename and line number where the exception was thrown.
If you stringify the exception it will use this method.

=head2 package

 my $package = $ex->package;

The package where the exception happened.

=head2 filename

 my $filename = $ex->filename;

The filename where the exception happened.

=head2 line

 my $line = $ex->line;

The line number where the exception happened.

=head2 code

 my $code = $ex->code;

The integer error code.

=head2 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<Exception::Class>

=item L<Class:Tiny>

=back

=cut

  my %human_codes;

  sub import ($, %args)
  {
    my $class = $args{class} || caller;

    {
      no strict 'refs';
      push @{ "$class\::ISA" }, 'Exception::FFI::ErrorCode::Base';
    }

    my $const_class = $args{const_class} || $class;

    foreach my $name (keys $args{codes}->%*)
    {
      my($code, $human) = do {
        my $v = $args{codes}->{$name};
        is_plain_arrayref $v ? @$v : ($v,$name);
      };
      constant->import("$const_class\::$name", $code);
      $human_codes{$class}->{$code} = $human;
    }
  }

  package Exception::FFI::ErrorCode::Base {

    use Class::Tiny qw( package filename line code );
    use Ref::Util qw( is_blessed_ref );
    use overload
        '""' => sub { shift->as_string },
        bool => sub { 1 }, fallback => 1;

    sub throw ($proto, @rest)
    {
      my($package, $filename, $line) = caller;

      my $self;
      if(is_blessed_ref $proto)
      {
        $self = $proto;
        $self->package($package);
        $self->filename($filename);
        $self->line($line);
      }
      else
      {
        $self = $proto->new(
          @rest,
          package  => $package,
          filename => $filename,
          line     => $line
        );
      }
      die $self;
    }

    sub strerror ($self)
    {
      my $code = $self->code;
      $code = 0 unless defined $code;
      my $str = $human_codes{ref $self}->{$code};
      $str = sprintf "%s error code %s", ref $self, $self->code unless defined $str;
      return $str;
    }

    sub as_string ($self)
    {
      sprintf "%s at %s line %s.", $self->strerror, $self->filename, $self->line;
    }
  }
}

1;
