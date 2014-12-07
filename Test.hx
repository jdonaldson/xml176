class Test {
    static function main() {
        var r = new haxe.unit.TestRunner();
        r.add(new com.tenderowls.txml176.Xml176ParserTest());
        r.run();
    }
}
