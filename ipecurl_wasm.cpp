// --------------------------------------------------------------------
// ipecurl for web assembly
// --------------------------------------------------------------------
/*

    This file is part of the extensible drawing editor Ipe.
    Copyright (c) 1993-2024 Otfried Cheong

    Ipe is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    As a special exception, you have permission to link Ipe with the
    CGAL library and distribute executables, as long as you follow the
    requirements of the Gnu General Public License in regard to all of
    the software in the executable aside from CGAL.

    Ipe is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with Ipe; if not, you can find it at
    "http://www.gnu.org/copyleft/gpl.html", or write to the Free
    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*/

#include "ipebase.h"
#include <emscripten/fetch.h>

using namespace ipe;

#define TEXNAME "ipetemp.tex"
#define PDFNAME "ipetemp.pdf"
#define LOGNAME "ipetemp.log"
//#define URLNAME "url1.txt"

int Platform::runLatex(String dir, LatexType engine, String docname) noexcept
{
  String command = (engine == LatexType::Xetex) ?
    "xelatex" : (engine == LatexType::Luatex) ?
    "lualatex" : "pdflatex";
  
  String tex = Platform::readFile(dir + "/" + TEXNAME);
  if (tex.empty()) {
    fprintf(stderr, "Cannot read Latex source from '%s'.\n", TEXNAME);
    return -3;
  }
  // fprintf(stderr, "Compiling %d bytes of tex in %s using %s.\n", tex.size(), (dir + "/" + TEXNAME).z(), command.z());

  String url = "/data?target=ipetemp.tex&command=";
  url += command;

  // ipeDebug("URL: '%s'", url.z());

  // need to send Latex source as a tarball
  Buffer tarHeader(512);
  char *p = tarHeader.data();
  memset(p, 0, 512);
  strcpy(p, "ipetemp.tex");
  strcpy(p + 100, "0000644"); // mode
  strcpy(p + 108, "0001750"); // uid 1000
  strcpy(p + 116, "0001750"); // gid 1000
  sprintf(p + 124, "%011o", tex.size());
  p[136] = '0';  // time stamp, fudge it
  p[156] = '0';  // normal file
  // checksum
  strcpy(p + 148, "        ");
  uint32_t checksum = 0;
  for (const char *q = p; q < p + 512; ++q)
    checksum += uint8_t(*q);
  sprintf(p + 148, "%06o", checksum);
  p[155] = ' ';

  String mime;
  StringStream ss(mime);
  ss << "--------------------------f0324ce8daa3cc53\r\n"
     << "Content-Disposition: form-data; name=\"file\"; filename=\"tar.txt\"\r\n"
     << "Content-Type: text/plain\r\n\r\n";
  for (const char *q = p; q < p + 512;)
    ss.putChar(*q++);
  ss << tex;
  int i = tex.size();
  while ((i & 0x1ff) != 0) {  // fill a 512-byte block
    ss.putChar('\0');
    ++i;
  }
  for (int i = 0; i < 1024; ++i)  // add two empty blocks
    ss.putChar('\0');
  ss << "\r\n--------------------------f0324ce8daa3cc53--\r\n";
  // fprintf(stderr, "Compressed %d bytes of mime data.\n", mime.size());


  emscripten_fetch_attr_t attr;
  emscripten_fetch_attr_init(&attr);
  strcpy(attr.requestMethod, "POST");
  const char* headers[] = {
      "User-Agent", "ipecurl_wasm", 
      "Content-Type", "multipart/form-data; boundary=------------------------f0324ce8daa3cc53",
      NULL};
  attr.requestHeaders = headers;
  attr.requestData = (char *) mime.z();
  attr.requestDataSize = mime.size();
  attr.attributes = EMSCRIPTEN_FETCH_LOAD_TO_MEMORY | EMSCRIPTEN_FETCH_REPLACE;
  // fprintf(stderr, "About to post to %s with attr %d.\n", url.z(), attr.attributes);
  emscripten_fetch_t *fetch = emscripten_fetch(&attr, url.z());
  
  while (fetch && fetch->readyState < 4) {
    // fprintf(stderr, "Waiting for fetch in readyState %d.\n", fetch->readyState);
    emscripten_sleep(100);
  }
  // if (fetch) fprintf(stderr, "readyState %d\n", fetch->readyState);

  String pdf;
  if (!fetch) {
    fprintf(stderr, "Initiating XHR request failed, got NULL as fetch response.\n");
    StringStream err(pdf);
    err << "! A request error occurred using the Latex cloud service\n";
    err << "Code:   NULL\n";
    err << "Domain: " << url.z() << "\n";
    err << "Error:  emscripten_fetch(...) returned NULL\n";
  } else if (fetch->status != 200) {
    fprintf(stderr, "Downloading %s failed, HTTP failure status code: %d.\n", fetch->url, fetch->status);
    StringStream err(pdf);
    err << "! A network error occurred using the Latex cloud service\n";
    err << "Code:   " << fetch->status << "\n";
    err << "Domain: " << fetch->url << "\n";
    err << "Error:  " << fetch->statusText << "\n";
  } else {
    // fprintf(stderr, "Finished downloading %llu bytes from URL %s:\n", fetch->numBytes, fetch->url);
    // fprintf(stderr, "%s\n", String((const char *) fetch->data, fmin(fetch->numBytes,100)).z());
    pdf = String((const char *) fetch->data, fetch->numBytes);
  }
  emscripten_fetch_close(fetch);

  // generate logfile
  FILE *log = Platform::fopen((dir + "/" + LOGNAME).z(), "wb");
  fprintf(log, "entering extended mode: using latexonline at '%s'\n", url.z());

  if (pdf.left(4) == "%PDF") {
    FILE * out = fopen((dir + "/" + PDFNAME).z(), "wb");
    if (!out) {
      fprintf(stderr, "Cannot open '%s' for writing.\n", PDFNAME);
      return -4;
    }
    fwrite(pdf.data(), 1, pdf.size(), out);
    fclose(out);
  } else {
    // an error happened during Latex run: pdf is actually a log
    fwrite(pdf.data(), 1, pdf.size(), log);
  }
  fclose(log);
  return 0;
}

// --------------------------------------------------------------------
