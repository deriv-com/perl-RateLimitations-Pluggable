use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'RateLimitations::Pluggable',
    AUTHOR             => q{Binary.com <support@binary.com>},
    VERSION_FROM       => 'lib/RateLimitations/Pluggable.pm',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => "6.64",
    },
    TEST_REQUIRES => {
        'Test::More'                      => 0,
        'Test::FailWarnings'              => 0,
      },
    PREREQ_PM => {
        'Moo' => 0,
    },
    LICENSE    => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/binary-com/perl-RateLimitations-Pluggable',
        }
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {FILES => 'RateLimitations-Pluggable*'},
);
