//
//  parser.mm
//  Leviathan
//
//  Created by Steven on 10/19/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#include "parser.h"

#include "lexer.h"

namespace Leviathan {
    
    std::pair<Coll*, ParserError> parseColl(std::vector<Token*>::iterator iter, Coll::Type collType, Token::Type endToken) {
        Coll* coll;
        ParserError error = {ParserError::NoError};
        
        Token* firstToken = *iter;
        iter++;
        
        std::cout << firstToken->type << std::endl;
        std::cout << (*iter)->type << std::endl;
        
        coll = new Coll;
        coll->collType = collType;
        
        coll->open_token = firstToken;
        coll->close_token = *iter;
        
        std::cout << coll->collType << std::endl;
        
        return std::make_pair(coll, error);
    }
    
    std::pair<Coll*, ParserError> parse(std::string const& raw) {
        std::pair<std::vector<Token*>, ParserError> result = lex(raw);
        
        std::vector<Token*> tokens = result.first;
        ParserError error = result.second;
        
        Coll* top_level_coll;
        
        if (error.type == ParserError::NoError) {
            std::pair<Coll*, ParserError> result = parseColl(tokens.begin(), Coll::TopLevel, Token::FileEnd);
            
            top_level_coll = result.first;
            error = result.second;
        }
        
        return std::make_pair(top_level_coll, error);
    }
    
}
