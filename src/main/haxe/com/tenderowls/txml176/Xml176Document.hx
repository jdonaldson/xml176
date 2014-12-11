
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

typedef Pos = { from:Int, ?to:Int }
