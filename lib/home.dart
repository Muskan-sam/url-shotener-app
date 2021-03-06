import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final textController = TextEditingController();
  var _shortenedUrl = "";
  var _lastShortenedUrl = "";
  bool isShorteningUrl = false;

  @override
  void initState() {
    super.initState();
    getLastUrlFromSharedPreferences();
  }

  Future<String> callApi(String url) async {
    Dio dio = Dio();
    var response = await dio.get("https://api.shrtco.de/v2/shorten?url=" + url);
    // print(response);
    if (response.statusCode != 201) {
      return Future.error("Failed to shorten the link!");
    }
    return response.data["result"]["full_short_link"];
  }

  saveToSharedPreferences(String shortenedUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("lastUrl", shortenedUrl);
  }

  getLastUrlFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var lastUrl = prefs.getString("lastUrl") ?? "";
    setState(() {
      _lastShortenedUrl = lastUrl;
    });
  }

  _shareUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    Share.share(url);
  }

  _launchURL(String _url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Let's shorten URL's!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              Container(
                child: _shortenedUrl != ""
                    ? InkWell(
                  onTap: () {
                    _launchURL(_shortenedUrl);
                  },
                  onLongPress: () {
                    _shareUrl(_shortenedUrl);
                  },
                  child: Text(
                    _shortenedUrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                )
                    : const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Go ahead and shorten links, it will appear here!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              SizedBox(
                height: 150,
                width: 350,
                child: Card(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.link),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Input your URL to shorten",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: textController,
                          style: const TextStyle(color: Colors.black),
                          enableInteractiveSelection: true,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'http://'),
                        ),
                      ),
                      !isShorteningUrl
                          ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: const Color(0XFF22272C)),
                        onPressed: () async {
                          setState(() {
                            isShorteningUrl = true;
                          });
                          var inputUrl = textController.text;
                          //print(inputUrl);
                          try {
                            var shortenedUrl = await callApi(inputUrl);
                            await saveToSharedPreferences(shortenedUrl);
                            setState(() {
                              _shortenedUrl = shortenedUrl;
                              _lastShortenedUrl = shortenedUrl;
                              isShorteningUrl = false;
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to shorten URL!"),
                              ),
                            );
                            setState(() {
                              isShorteningUrl = false;
                            });
                          }
                        },
                        child: const Text("Shorten"),
                      )
                          : const CircularProgressIndicator(
                        color: Color(0XFF22272C),
                      ),
                    ],
                  ),
                ),
              ),
              _lastShortenedUrl != ""
                  ? InkWell(
                    onTap: () {
                      _launchURL(_lastShortenedUrl);
                    },
                    onLongPress: () {
                      _shareUrl(_lastShortenedUrl);
                    },
                    child: Text(
                        "Your last shortened url was: $_lastShortenedUrl"),
                  )
                  : const Text("You do not have any links saved!"),
            ],
          ),
        ),
      ),
    );
  }
}