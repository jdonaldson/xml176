/*
 * Copyright (C)2005-2012 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package com.tenderowls.txml176;

using StringTools;

@:enum
abstract State(Int)
{
	var IGNORE_SPACES = 0;
	var BEGIN         = 1;
	var BEGIN_NODE    = 2;
	var TAG_NAME      = 3;
	var BODY          = 4;
	var ATTRIB_NAME   = 5;
	var EQUALS        = 6;
	var ATTVAL_BEGIN  = 7;
	var ATTRIB_VAL    = 8;
	var CHILDS        = 9;
	var CLOSE         = 10;
	var WAIT_END      = 11;
	var WAIT_END_RET  = 12;
	var PCDATA        = 13;
	var HEADER        = 14;
	var COMMENT       = 15;
	var DOCTYPE       = 16;
	var CDATA         = 17;
	var ESCAPE        = 18;
	var TDATA_ATT     = 19;
	var TDATA         = 20;
}

#if debug
class StateUtil {
    public static function val(arg:State) {
        return switch(arg){
            case IGNORE_SPACES :  "IGNORE_SPACES";
            case BEGIN         :  "BEGIN";
            case BEGIN_NODE    :  "BEGIN_NODE";
            case TAG_NAME      :  "TAG_NAME";
            case BODY          :  "BODY";
            case ATTRIB_NAME   :  "ATTRIB_NAME";
            case EQUALS        :  "EQUALS";
            case ATTVAL_BEGIN  :  "ATTVAL_BEGIN ";
            case ATTRIB_VAL    :  "ATTRIB_VAL";
            case CHILDS        :  "CHILDS";
            case CLOSE         :  "CLOSE";
            case WAIT_END      :  "WAIT_END";
            case WAIT_END_RET  :  "WAIT_END_RET";
            case PCDATA        :  "PCDATA";
            case HEADER        :  "HEADER";
            case COMMENT       :  "COMMENT";
            case DOCTYPE       :  "DOCTYPE";
            case CDATA         :  "CDATA";
            case ESCAPE        :  "ESCAPE";
            case TDATA_ATT     :  "TDATA_ATT";
            case TDATA         :  "TDATA";
        }
    }
}
#end



class Xml176Document {

    public var document(default,null):Xml;

    var ePosInfos: Map<Xml, Pos>;
    var aPosInfos: Map<Xml, Map<String, Pos>>;
    var tdata:     Map<Xml, Array<String>>;
    var tdataAtt:  Map<Xml, Map<String, String>>;

    public function new(doc:Xml, ePosInfos, aPosInfos, tdata, tdataAtt:Map<Xml, Map<String, String>>) {
        this.document = doc;
        this.ePosInfos = ePosInfos;
        this.aPosInfos = aPosInfos;
        this.tdata = tdata;
        this.tdataAtt = tdataAtt;
    }

    public function getNodePosition(node:Xml):Pos {
        return ePosInfos.get(node);
    }

    public function getAttrPosition(node:Xml, attr:String):Pos {
        return aPosInfos.get(node).get(attr);
    }

    public function getTemplates(node:Xml):Array<String> {
        return tdata.get(node);
    }

    public function getAttributeTemplate(node:Xml, attr:String):String {
        // trace('----');
        // trace(tdataAtt + " is the value for tdataAtt");
        // trace('----');
        // trace(node + " is the value for node");
        // trace('----');
        var node_data = tdataAtt.get(node);
        return node_data != null ? node_data.get(attr) : null;
    }
}

class Xml176Parser
{
	static public function parse(str:String)
	{
		var xmlDoc = Xml.createDocument();
        var ePosInfos = new Map<Xml, Pos>();
        var aPosInfos = new Map<Xml, Map<String, Pos>>();
        var tdata     = new Map<Xml, Array<String>>();
        var tdataAtt  = new Map<Xml, Map<String, String>>();

		doParse(str, 0, ePosInfos, aPosInfos, tdata, tdataAtt, xmlDoc);

		return new Xml176Document(xmlDoc, ePosInfos, aPosInfos, tdata, tdataAtt);
	}
	
	static function doParse(
	        str:String, 
	        p:          Int = 0,
	        ePosInfos:  Map<Xml, Pos>,
	        aPosInfos:  Map<Xml, Map<String, Pos>>,
	        tdata:  Map<Xml, Array<String>>,
	        tdataAtt: Map<Xml, Map<String, String>>,
	        ?parent:    Xml
	        ) : Int
	{
		var xml:Xml = null;
        var xmlPos:Pos = { from: 0 };
		var state:State = BEGIN;
		var next:State = BEGIN;
		var aname = null;
		var start = 0;
		var nsubs = 0;
		var nbrackets = 0;
		var c = str.fastCodeAt(p);
		var buf = new StringBuf();
		var t_depth = 0;
		
		while (!StringTools.isEof(c))
		{
			// trace(StateUtil.val(state));
			switch(state)
			{
				case IGNORE_SPACES:
					switch(c)
					{
						case
							'\n'.code,
							'\r'.code,
							'\t'.code,
							' '.code:
						default:
							state = next;
							continue;
					}
				case BEGIN:
					switch(c)
					{
						case '<'.code:
							state = IGNORE_SPACES;
							next = BEGIN_NODE;
						default:
							start = p;
							state = PCDATA;
							continue;
					}
				case PCDATA:
					if (c == '<'.code || c == '{'.code)
					{
						#if php
						var child = Xml.createPCDataFromCustomParser(buf.toString() + str.substr(start, p - start));
						#else
						var child = Xml.createPCData(buf.toString() + str.substr(start, p - start));
						#end
						buf = new StringBuf();
						parent.addChild(child);
						nsubs++;
						if (c == '<'.code){
                            state = IGNORE_SPACES;
                            next = BEGIN_NODE;

                        } else if (c == '{'.code){
                            state = TDATA;
                            start = p + 1; // ignore the leading '{'
                            next = BEGIN_NODE;
                        }
					}
					else if (c =='\\'.code){ 
                        //pcdata needs to handle escapes
					    p++;
                    }
					#if !flash9
					else if (c == '&'.code) {
						buf.addSub(str, start, p - start);
						state = ESCAPE;
						next = PCDATA;
						start = p + 1;
					}
					#end
				case CDATA:
					if (c == ']'.code && str.fastCodeAt(p + 1) == ']'.code && str.fastCodeAt(p + 2) == '>'.code)
					{
						var child = Xml.createCData(str.substr(start, p - start));
						parent.addChild(child);
						nsubs++;
						p += 2;
						state = BEGIN;
					}
				case TDATA:
					if (c == "}".code )
					{
					    if (t_depth == 0){
                      var child = Xml.createCData(str.substr(start, p - start));
                      parent.addChild(child);
                      nsubs++;
                      p += 2;
                      state = BEGIN;
                        } else {
                            t_depth--;
                        }
					}
					else if (c== "{".code){ // recursive 
					    t_depth++;
					}
					else if (c == "\\".code){ // escape character
					    p++;
                    }
				case BEGIN_NODE:
					switch(c)
					{
						case '!'.code:
							if (str.fastCodeAt(p + 1) == '['.code)
							{
								p += 2;
								if (str.substr(p, 6).toUpperCase() != "CDATA[")
									throw("Expected <![CDATA[");
								p += 5;
								state = CDATA;
								start = p + 1;
								throw("Embedded CDATA is not supported");
							}
							else if (str.fastCodeAt(p + 1) == 'D'.code || str.fastCodeAt(p + 1) == 'd'.code)
							{
								if(str.substr(p + 2, 6).toUpperCase() != "OCTYPE")
									throw("Expected <!DOCTYPE");
								p += 8;
								state = DOCTYPE;
								start = p + 1;
							}
							else if( str.fastCodeAt(p + 1) != '-'.code || str.fastCodeAt(p + 2) != '-'.code )
								throw("Expected <!--");
							else
							{
								p += 2;
								state = COMMENT;
								start = p + 1;
							}
						case '?'.code:
							state = HEADER;
							start = p;
						case '/'.code:
							if( parent == null )
								throw("Expected node name");
							start = p + 1;
							state = IGNORE_SPACES;
							next = CLOSE;
						default:
							state = TAG_NAME;
							start = p;
							continue;
					}
				case TAG_NAME:
					if (!isValidChar(c))
					{
						if( p == start )
							throw("Expected node name");
						xml = Xml.createElement(str.substr(start, p - start));
						xml.toString(); // TODO: get rid of this strange workaround
                        ePosInfos.set(xml, {from:start, to: p});
						parent.addChild(xml);
						state = IGNORE_SPACES;
						next = BODY;
						continue;
					}
				case BODY:
					switch(c)
					{
						case '/'.code:
							state = WAIT_END;
							nsubs++;
						case '>'.code:
							state = CHILDS;
							nsubs++;
						default:
							state = ATTRIB_NAME;
							start = p;
							continue;
					}
				case ATTRIB_NAME:
					if (!isValidChar(c))
					{
						var tmp;
						if( start == p )
							throw("Expected attribute name");
						tmp = str.substr(start,p-start);
						aname = tmp;
						if( xml.exists(aname) )
							throw("Duplicate attribute");
						state = IGNORE_SPACES;
						next = EQUALS;
						continue;
					}
				case EQUALS:
					switch(c)
					{
						case '='.code:
							state = IGNORE_SPACES;
							next = ATTVAL_BEGIN;
						default:
							throw("Expected =");
					}
				case ATTVAL_BEGIN:
					switch(c)
					{
						case '"'.code, '\''.code:
							state = ATTRIB_VAL;
							start = p;
						case '{'.code:
							state = TDATA_ATT;
							start = p;
						default:
							throw("Expected \"");
					}
				case ATTRIB_VAL:
					if (c == str.fastCodeAt(start))
					{
						var val = str.substr(start+1,p-start-1);
						xml.set(aname, val);

                        var pi = aPosInfos.get(xml);
                        if (pi == null) {
                            pi = new Map<String, Pos>();
                            aPosInfos.set(xml, pi);
                        }
                        pi.set(aname, {from:start-aname.length, to: start});
						state = IGNORE_SPACES;
						next = BODY;
					} 
				case TDATA_ATT:
					if (c == "}".code )
					{
						var val = str.substr(start+1,p-start-1);
					    if (t_depth == 0){
                            xml.set(aname, '');

					        // var child = Xml.createElement("TXML176:ATTRUBUTETDATA");
					        // child.set("attribute", aname);
                            // var child_cdata = Xml.createCData(str.substr(start, p - start));
                            // child.addChild(child_cdata);
                            // parent.addChild(child);

                            var pi = aPosInfos.get(xml);
                            if (pi == null) {
                                pi = new Map<String, Pos>();
                                aPosInfos.set(xml, pi);
                            }
                            pi.set(aname, {from:start-aname.length, to: start});
                            var tapi = tdataAtt.get(xml);
                            if (tapi == null){
                                tapi = new haxe.ds.StringMap<String>();
                                tdataAtt.set(xml, tapi);
                            }
                            tapi.set(aname, val);

                            state = IGNORE_SPACES;
                            next = BODY;
                        } else {
                            t_depth--;
                        }
					}
					else if (c== "{".code){ // recursive 
					    t_depth++;
					}
					else if (c == "\\".code){ // escape character
					    p++;
                    }
				case CHILDS:
					p = doParse(str, p, ePosInfos, aPosInfos, tdata, tdataAtt, xml);
					start = p;
					state = BEGIN;
				case WAIT_END:
					switch(c)
					{
						case '>'.code:
							state = BEGIN;
						default :
							throw("Expected >");
					}
				case WAIT_END_RET:
					switch(c)
					{
						case '>'.code:
							if( nsubs == 0 )
								parent.addChild(Xml.createPCData(""));
							return p;
						default :
							throw("Expected >");
					}
				case CLOSE:
					if (!isValidChar(c))
					{
						if( start == p )
							throw("Expected node name");

						var v = str.substr(start,p - start);
						if (v != parent.nodeName)
							throw "Expected </" +parent.nodeName + ">";

						state = IGNORE_SPACES;
						next = WAIT_END_RET;
						continue;
					}
				case COMMENT:
					if (c == '-'.code && str.fastCodeAt(p +1) == '-'.code && str.fastCodeAt(p + 2) == '>'.code)
					{
						parent.addChild(Xml.createComment(str.substr(start, p - start)));
						p += 2;
						state = BEGIN;
					}
				case DOCTYPE:
					if(c == '['.code)
						nbrackets++;
					else if(c == ']'.code)
						nbrackets--;
					else if (c == '>'.code && nbrackets == 0)
					{
						parent.addChild(Xml.createDocType(str.substr(start, p - start)));
						state = BEGIN;
					}
				case HEADER:
					if (c == '?'.code && str.fastCodeAt(p + 1) == '>'.code)
					{
						p++;
						var str = str.substr(start + 1, p - start - 2);
						parent.addChild(Xml.createProcessingInstruction(str));
						state = BEGIN;
					}
				case ESCAPE:
					if (c == ';'.code)
					{
						var s = str.substr(start, p - start);
						if (s.fastCodeAt(0) == '#'.code) {
							var i = s.fastCodeAt(1) == 'x'.code
								? Std.parseInt("0" +s.substr(1, s.length - 1))
								: Std.parseInt(s.substr(1, s.length - 1));
							buf.add(String.fromCharCode(i));
						} else if (!escapes.exists(s))
							buf.add('&$s;');
						else
							buf.add(escapes.get(s));
						start = p + 1;
						state = next;
					}
			}
			c = str.fastCodeAt(++p);
		}
		
		if (state == BEGIN)
		{
			start = p;
			state = PCDATA;
		}
		
		if (state == PCDATA)
		{
			if (p != start || nsubs == 0)
				parent.addChild(Xml.createPCData(buf.toString() + str.substr(start, p - start)));
			return p;
		}
		
		throw "Unexpected end";
	}
	
	static inline function isValidChar(c) {
		return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code) || c == ':'.code || c == '.'.code || c == '_'.code || c == '-'.code;
	}

    static var escapes = {
        var h = new haxe.ds.StringMap();
        h.set("lt", "<");
        h.set("gt", ">");
        h.set("amp", "&");
        h.set("quot", '"');
        h.set("apos", "'");
        h.set("nbsp", String.fromCharCode(160));
        h;
    }
}

typedef Pos = { from:Int, ?to:Int }

