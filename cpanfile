requires 'Moo';
requires 'perl', '5.006';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on build => sub {
    requires 'ExtUtils::MakeMaker';
    requires 'Test::FailWarnings';
    requires 'Test::More';
};
