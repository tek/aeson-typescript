{-# LANGUAGE CPP #-}

module Data.Aeson.TypeScript.Formatting where

import Data.Aeson.TypeScript.Types
import Data.Function ((&))
import qualified Data.List as L
import Data.Maybe
import Data.String.Interpolate
import qualified Data.Text as T

#if !MIN_VERSION_base(4,11,0)
import Data.Monoid
#endif


-- | Same as 'formatTSDeclarations'', but uses default formatting options.
formatTSDeclarations :: [TSDeclaration] -> String
formatTSDeclarations = formatTSDeclarations' defaultFormattingOptions

-- | Format a single TypeScript declaration. This version accepts a FormattingOptions object in case you want more control over the output.
formatTSDeclaration :: FormattingOptions -> TSDeclaration -> String
formatTSDeclaration (FormattingOptions {..}) (TSTypeAlternatives name genericVariables names maybeDoc) =
  makeDocPrefix maybeDoc <> mainDeclaration
  where
    mainDeclaration = case typeAlternativesFormat of
      Enum -> "blah"
      EnumWithType -> "blah"
      TypeAlias -> "blah"

    alternatives = T.intercalate " | " (fmap T.pack names)
    alternativesEnum = T.intercalate ", " $ [toEnumName entry | entry <- T.pack <$> names]
    alternativesEnumWithType = T.intercalate ", " $ [toEnumName entry <> "=" <> entry | entry <- T.pack <$> names]
    enumType = "blah" :: T.Text
    toEnumName = T.replace "\"" ""

formatTSDeclaration (FormattingOptions {..}) (TSInterfaceDeclaration interfaceName genericVariables (filter (not . isNoEmitTypeScriptField) -> members) maybeDoc) =
  makeDocPrefix maybeDoc <> "blah" where
      ls = T.intercalate "\n" $ [indentTo numIndentSpaces (T.pack (formatTSField member <> ";")) | member <- members]
      modifiedInterfaceName = (\(li, name) -> li <> interfaceNameModifier name) . splitAt 1 $ interfaceName

formatTSDeclaration _ (TSRawDeclaration text) = text

indentTo :: Int -> T.Text -> T.Text
indentTo numIndentSpaces input = T.intercalate "\n" [padding <> line | line <- T.splitOn "\n" input]
  where padding = T.replicate numIndentSpaces " "

exportPrefix :: ExportMode -> String
exportPrefix ExportEach = "export "
exportPrefix ExportNone = ""

-- | Format a list of TypeScript declarations into a string, suitable for putting directly into a @.d.ts@ file.
formatTSDeclarations' :: FormattingOptions -> [TSDeclaration] -> String
formatTSDeclarations' options allDeclarations =
  declarations & fmap (T.pack . formatTSDeclaration (validateFormattingOptions options declarations))
               & T.intercalate "\n\n"
               & T.unpack
  where
    removedDeclarations = filter isNoEmitTypeScriptDeclaration allDeclarations

    getDeclarationName :: TSDeclaration -> Maybe String
    getDeclarationName (TSInterfaceDeclaration {..}) = Just interfaceName
    getDeclarationName (TSTypeAlternatives {..}) = Just typeName
    _ = Nothing

    removedDeclarationNames = mapMaybe getDeclarationName removedDeclarations

    removeReferencesToRemovedNames :: [String] -> TSDeclaration -> TSDeclaration
    removeReferencesToRemovedNames removedNames decl@(TSTypeAlternatives {..}) = decl { alternativeTypes = [x | x <- alternativeTypes, not (x `L.elem` removedNames)] }
    removeReferencesToRemovedNames _ x = x

    declarations = allDeclarations
                 & filter (not . isNoEmitTypeScriptDeclaration)
                 & fmap (removeReferencesToRemovedNames removedDeclarationNames)

validateFormattingOptions :: FormattingOptions -> [TSDeclaration] -> FormattingOptions
validateFormattingOptions options@FormattingOptions{..} decls
  | typeAlternativesFormat == Enum && isPlainSumType decls = options
  | typeAlternativesFormat == EnumWithType && isPlainSumType decls = options { typeNameModifier = flip (<>) "Enum" }
  | otherwise = options { typeAlternativesFormat = TypeAlias }
  where
    isInterface :: TSDeclaration -> Bool
    isInterface TSInterfaceDeclaration{} = True
    isInterface _ = False

    -- Plain sum types have only one declaration with multiple alternatives
    -- Units (data U = U) contain two declarations, and thus are invalid
    isPlainSumType ds = (not . any isInterface $ ds) && length ds == 1

formatTSField :: TSField -> String
formatTSField (TSField optional name typ maybeDoc) = makeDocPrefix maybeDoc <> "blah"

makeDocPrefix :: Maybe String -> String
makeDocPrefix maybeDoc = case maybeDoc of
  Nothing -> ""
  Just (T.pack -> text) -> ["// " <> line | line <- T.splitOn "\n" text]
                        & T.intercalate "\n"
                        & (<> "\n")
                        & T.unpack

getGenericBrackets :: [String] -> String
getGenericBrackets [] = ""
getGenericBrackets xs = "blah"

-- * Support for @no-emit-typescript

noEmitTypeScriptAnnotation :: String
noEmitTypeScriptAnnotation = "@no-emit-typescript"

isNoEmitTypeScriptField (TSField {fieldDoc=(Just doc)}) = noEmitTypeScriptAnnotation `L.isInfixOf` doc
isNoEmitTypeScriptField _ = False

isNoEmitTypeScriptDeclaration (TSInterfaceDeclaration {interfaceDoc=(Just doc)}) = noEmitTypeScriptAnnotation `L.isInfixOf` doc
isNoEmitTypeScriptDeclaration (TSTypeAlternatives {typeDoc=(Just doc)}) = noEmitTypeScriptAnnotation `L.isInfixOf` doc
isNoEmitTypeScriptDeclaration _ = False
