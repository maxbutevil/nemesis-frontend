


import "package:flutter/material.dart";
import "/client.dart" as client;
import "/user_data.dart";
import '/utils.dart';

class MatchListPage extends StatefulWidget {
  
  const MatchListPage({ super.key });
  
  @override createState() => MatchListPageState();
  
}

class MatchListPageState extends State<MatchListPage> {
  
  MatchListPageState();
  
  @override build(BuildContext context) {
    
    return ObservableBuilder(
      value: client.matches,
      builder: (_, matches) {
        
        if (matches == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        const divider = Divider(
          height: 2.0,
          thickness: 2.0,
          indent: 10.0,
          endIndent: 10.0
        );
        
        var matchesList = matches.values.toList();
        
        return ListView.separated(
          itemCount: matchesList.length,
          itemBuilder: (_, i) => buildMatchTile(matchesList[i]),
          separatorBuilder: (_, i) => divider
        );
        
        /*
        return ListView.builder(
          itemCount: matchesList.length,
          itemBuilder: (_, index) => buildMatchTile(matchesList[index])
        );
        */
        
      }
    );
    
  }
  Widget buildMatchTile(Match match) {
    
    return ObservableBuilder(
      value: match.messages,
      builder: (_, messages) {
        
        var message = match.getLatestMessage();
        
        return ListTile(
          key: ValueKey(match.profileData.id),
          title: Text(match.profileData.name),
          subtitle: message == null ? null : Text(message.content), // might need something for long messages
          onTap: () => openMatch(match)
        );
        
      }
    );
    
    
    
  }
  
  void openMatch(Match match) {
    
    Globals.navigatorState?.push(
      MaterialPageRoute(builder: (_) => MatchPage(match))
    );
    
  }
  
}


class MatchPage extends StatefulWidget {
  
  final Match match;
  
  MatchPage(Match match) : match = match, super(key: ValueKey(match.profileData.id));
  
  @override createState() => MatchPageState();
  
}
class MatchPageState extends State<MatchPage> {
  
  Match get match => widget.match;
  ProfileData get profileData => match.profileData;
  
  MatchPageState();
  
  @override build(BuildContext context) {
    
    return Scaffold(
      
      resizeToAvoidBottomInset: true,
      
      appBar: AppBar(
        title: Text(profileData.name)
      ),
      //bottomNavigationBar: const TextField(),
      
      body: ChatView(match),
      
    );
    
  }
  
}


class ChatView extends StatefulWidget {
  
  final Match match;
  
  const ChatView(this.match, { super.key });
  
  @override createState() => ChatViewState();
  
}
class ChatViewState extends State<ChatView> {
  
  ChatViewState();
  
  Match get match => widget.match;
  ProfileData get profileData => match.profileData;
  //List<ChatMessage> get messages => match.messages;
  
  final _textFieldController = TextEditingController();
  
  void sendMessage() {
      
    if (_textFieldController.text.isNotEmpty) {
      client.handleOutgoingMessage(match, _textFieldController.text);
      _textFieldController.clear();
    }
    
  }
  
  @override build(BuildContext context) {
    
    return Column(
      children: [
        buildMessageList(),
        const Divider(height: 2.0, thickness: 2.0),
        buildTextField()
      ]
    );
    
    
    
  }
  
  Widget buildMessageList() {
    
    return ObservableBuilder(
      value: match.messages,
      builder: (_, messages) {
        print(messages);
        return Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, i) => buildMessageBubble(messages[messages.length - i - 1]),
          )
        );
      }
    );
    
  }
  Widget buildTextField() {
    
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 6.0),
            child: TextField(
              minLines: 1,
              maxLines: 10,
              controller: _textFieldController
            )
          ),
        ),
        TextButton(
          onPressed: sendMessage,
          child: const Icon(Icons.send)
        )
      ]
    );
    
  }
  Widget buildMessageBubble(ChatMessage message) {
    
    return Align(
      alignment: message.outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 100.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0)
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Text(message.content)
          )
        )
      )
    );
    
  }
  
  
}





