use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'RateLimitations::Pluggable',
    AUTHOR             => q{Binary.com <support@binary.com>},
    VERSION_FROM       => 'lib/RateLimitations/Pluggable.pm',
    ( eval { ExtUtils::MakeMaker->VERSION(6.64) } ?
        (
            CONFIGURE_REQUIRES => {
                "ExtUtils::MakeMaker" => "6.64",
            },
            BUILD_REQUIRES => {
                'Test::More'                      => 0,
                'Test::FailWarnings'              => 0,
                'Devel::Cover'                    => '1.23',
                'Devel::Cover::Report::Coveralls' => '0.11',
                'Devel::Cover::Report::Codecov'   => '0.14',

            },
            PREREQ_PM => {
              'Moo' => 0,
            },
        ) : (
            PREREQ_PM => {
                "ExtUtils::MakeMaker" => '6.64',
                'Test::More'                       => 0,
                'Test::FailWarnings'               => 0,
                'Moo'                              => 0,
                 'Devel::Cover'                    => '1.23',
                 'Devel::Cover::Report::Coveralls' => '0.11',
                 'Devel::Cover::Report::Codecov'   => '0.14',
                         },
        )
    ),
    ( eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
        (
            META_MERGE => {
                resources => {
                    repository => 'https://github.com/binary-com/perl-RateLimitations-Pluggable',
                },
            }
        ) : ()
    ),
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( MIN_PERL_VERSION => '5.8.1') : ()),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RateLimitations-Pluggable*' },
);
