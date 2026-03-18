on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'test' => sub {
  if ($] < 5.014) {
    # Pin to versions that still support older Perls
    requires "Math::BigInt", ">= 1.997, < 2.000000";
    requires "Test::More", ">= 0.90, < 1.302200";
  } else {
    requires "Math::BigInt" => "1.997";
    requires "Test::More" => "0.90";
  }
};
