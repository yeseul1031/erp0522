
const jsdom = require("jsdom");
const { JSDOM } = jsdom;
const fs = require("fs");
const html = fs.readFileSync("docs_check/neo.html", "utf8");
const dom = new JSDOM(html, { runScripts: "dangerously" });
try {
  dom.window.setPoListRole('ceo');
  console.log("Success! Display is:", dom.window.document.getElementById('pg-ceo-approval').style.display);
  console.log("pg-ceo-approval innerHTML length:", dom.window.document.getElementById('pg-ceo-approval').innerHTML.length);
} catch (e) {
  console.error(e);
}
