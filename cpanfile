requires 'Moo';
requires 'perl', '5.006';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on build => sub {
    requires 'Devel::Cover', '1.23';
    requires 'Devel::Cover::Report::Codecov', '0.14';
    requires 'Devel::Cover::Report::Coveralls', '0.11';
    requires 'ExtUtils::MakeMaker';
    requires 'Test::FailWarnings';
    requires 'Test::More';
};
