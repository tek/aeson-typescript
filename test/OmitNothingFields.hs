
module OmitNothingFields (main, tests) where

import Data.Aeson as A
import Data.Aeson.TypeScript.TH
import Data.Aeson.TypeScript.Types
import Data.Proxy
import Test.Hspec
import TestBoilerplate

$(testDeclarations "OmitNothingFields" (A.defaultOptions {omitNothingFields=True}))

main :: IO ()
main = hspec $ describe "OmitNothingFields" $ do
  it "encodes as expected" $ do
    let decls = getTypeScriptDeclarations (Proxy :: Proxy Optional)

    decls `shouldBe` [TSInterfaceDeclaration {
                         interfaceName = "Optional"
                         , interfaceGenericVariables = []
                         , interfaceMembers = [
                             TSField True "optionalInt" "number" Nothing
                             ]
                         , interfaceDoc = Nothing
                         }]

  tests
