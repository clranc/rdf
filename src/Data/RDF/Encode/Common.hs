{-# LANGUAGE OverloadedStrings #-}

module Data.RDF.Encode.Common where

import qualified Data.ByteString.Builder as B

import Data.Monoid

import Data.RDF.Types

import qualified Data.Text               as T
import qualified Data.Text.Encoding      as T

quoteString :: T.Text -> T.Text
quoteString = T.replace "\"" "\\\""

maybeBuilder :: Maybe B.Builder -> B.Builder
maybeBuilder Nothing  = mempty
maybeBuilder (Just b) = b

encodeEscapedIRI :: IRI -> B.Builder
encodeEscapedIRI i = B.byteString "<" <> encodeIRI i <> B.byteString ">"

encodeIRI :: IRI -> B.Builder
encodeIRI (IRI s a p q f) = mconcat
    [ T.encodeUtf8Builder s
    , B.byteString ":"
    , maybeBuilder (encodeIRIAuth <$> a)
    , B.byteString "/"
    , T.encodeUtf8Builder p
    , maybeBuilder (((B.byteString "?" <>) . T.encodeUtf8Builder) <$> q)
    , maybeBuilder (((B.byteString "#" <>) . T.encodeUtf8Builder) <$> f)
    ]

encodeIRIAuth :: IRIAuth -> B.Builder
encodeIRIAuth (IRIAuth u h p) = mconcat
    [ B.byteString "//"
    , maybeBuilder (((<> B.byteString "@") . T.encodeUtf8Builder) <$> u)
    , T.encodeUtf8Builder h
    , maybeBuilder (((B.byteString ":" <>) . T.encodeUtf8Builder) <$> p)
    ]

encodeLiteral :: Literal -> B.Builder
encodeLiteral (Literal v t) = mconcat
    [ B.byteString "\""
    , T.encodeUtf8Builder (quoteString v)
    , B.byteString "\""
    , encodeLiteralType t
    ]

encodeLiteralType :: LiteralType -> B.Builder
encodeLiteralType (LiteralIRIType i)  = mconcat [ B.byteString "^^"
                                                , encodeEscapedIRI i
                                                ]
encodeLiteralType (LiteralLangType l) = mconcat [ B.byteString "@"
                                                , T.encodeUtf8Builder l
                                                ]
encodeLiteralType LiteralUntyped      = mempty

encodeBlankNode :: BlankNode -> B.Builder
encodeBlankNode (BlankNode l) = B.byteString "_:" <> T.encodeUtf8Builder l

encodeSubject :: Subject -> B.Builder
encodeSubject (IRISubject i)   = encodeEscapedIRI i
encodeSubject (BlankSubject b) = encodeBlankNode b

encodePredicate :: Predicate -> B.Builder
encodePredicate (Predicate i) = encodeEscapedIRI i

encodeObject :: Object -> B.Builder
encodeObject (IRIObject i)     = encodeEscapedIRI i
encodeObject (LiteralObject l) = encodeLiteral l
encodeObject (BlankObject b)   = encodeBlankNode b
