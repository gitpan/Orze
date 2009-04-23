use inc::Module::Install;

name  'Orze';
author 'Olivier Schwander <olivier.schwander@ens-lyon.org>';
license 'perl';
all_from 'script/orze';

install_script 'script/orze';

requires 'DateTime'              => 0;
requires 'File::Copy::Recursive' => 0;
requires 'HTML::Entities'        => 0;
requires 'Image::Thumbnail'      => 0;
requires 'Pod::Simple::XHTML'    => 0;
requires 'String::Escape'        => 0;
requires 'Template'              => 0;
requires 'Text::Markdown'        => 0;
requires 'XML::RSS'              => 0;
requires 'XML::Twig'             => 0;
requires 'YAML'                  => 0;

#configure_requires 'ExtUtils::MakeMaker' => 0;
#test_requires 'ExtUtils::MakeMaker' => 0;
#requires 'ExtUtils::MakeMaker' => 0;

test_requires 'Test::Dependencies' => 0;

WriteAll;

