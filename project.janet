(declare-project
  :name "jurl"
  :description "jannet wrapper around libcurl"
  :author "Sepehr Aryani"
  :license "GPLv3"
  :url "https://github.com/sepisoad/jurl"
  :repo "https://github.com/sepisoad/jurl")

(def- shlike-grammar ~{
  :ws (set " \t\r\n")
  :escape (* "\\" (capture 1))
  :dq-string (accumulate (* "\"" (any (+ :escape (if-not "\"" (capture 1)))) "\""))
  :sq-string (accumulate (* "'" (any (if-not "'" (capture 1))) "'"))
  :token-char (+ :escape (* (not :ws) (capture 1)))
  :token (accumulate (some :token-char))
  :value (* (any (+ :ws)) (+ :dq-string :sq-string :token) (any :ws))
  :main (any :value)
})

(def- peg (peg/compile shlike-grammar))

(defn shsplit
  "Split a string into 'sh like' tokens, returns
   nil if unable to parse the string."
  [s]
  (peg/match peg s))

(defn pkg-config [what]
  (def f (file/popen (string "pkg-config " what)))
  (def v (->>
           (file/read f :all)
           (string/trim)
           shsplit))
  (unless (zero? (file/close f))
    (error "pkg-config failed!"))
  v)

(declare-native
  :name "curl"
  :cflags (pkg-config "libcurl --cflags")
  :lflags (pkg-config "libcurl --libs")
  :source ["src/curl.c"])
