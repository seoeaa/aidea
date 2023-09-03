import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:askaide/bloc/version_bloc.dart';
import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/helper.dart';
import 'package:askaide/helper/logger.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:askaide/helper/http.dart';
import 'package:url_launcher/url_launcher.dart';

class SignInScreen extends StatefulWidget {
  final SettingRepository settings;
  final String? username;

  const SignInScreen({super.key, required this.settings, this.username});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();

  final phoneNumberValidator = RegExp(r"^1[3456789]\d{9}$");

  var agreeProtocol = false;

  @override
  void initState() {
    super.initState();
    if (widget.username != null) {
      _usernameController.text = widget.username!;
    }

    context.read<VersionBloc>().add(VersionCheckEvent());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var customColors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: CustomSize.toolbarHeight,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: customColors.weakLinkColor,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/chat-chat');
            }
          },
        ),
      ),
      backgroundColor: customColors.backgroundColor,
      body: BackgroundContainer(
        setting: widget.settings,
        enabled: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Image.asset('assets/app.png'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedTextKit(
                    animatedTexts: [
                      ColorizeAnimatedText(
                        'AIdea',
                        textStyle: const TextStyle(fontSize: 30.0),
                        colors: [
                          Colors.purple,
                          Colors.blue,
                          Colors.yellow,
                          Colors.red,
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 15.0, right: 15.0, top: 15, bottom: 0),
                    child: TextFormField(
                      controller: _usernameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.singleLineFormatter
                      ],
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(200, 192, 192, 192)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: customColors.linkColor ?? Colors.green),
                        ),
                        floatingLabelStyle: TextStyle(
                          color: customColors.linkColor ?? Colors.green,
                        ),
                        isDense: true,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: AppLocale.account.getString(context),
                        labelStyle: const TextStyle(fontSize: 17),
                        hintText: AppLocale.accountInputTips.getString(context),
                        hintStyle: TextStyle(
                          color: customColors.textfieldHintColor,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      'После успешной верификации незарегистрированного номера телефона произойдет автоматическая регистрация.',
                      style: TextStyle(
                        color: customColors.weakTextColor?.withAlpha(80),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // 登录按钮
                  Container(
                    height: 45,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: customColors.linkColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: TextButton(
                      onPressed: onSigninSubmit,
                      child: const Text(
                        'Подтвердить',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),

                  _buildUserTermsAndPrivacy(customColors, context),
                  const SizedBox(height: 50),
                  // 三方登录
                  BlocBuilder<VersionBloc, VersionState>(
                    builder: (context, state) {
                      return _buildThirdPartySignInButtons(
                          context, customColors);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Row _buildUserTermsAndPrivacy(
      CustomColors customColors, BuildContext context) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.5,
          child: Theme(
            data: ThemeData(
              unselectedWidgetColor: customColors.weakTextColor?.withAlpha(180),
            ),
            child: Checkbox(
              activeColor: customColors.linkColor,
              value: agreeProtocol,
              onChanged: (agree) {
                setState(() {
                  agreeProtocol = !agreeProtocol;
                });
              },
            ),
          ),
        ),
        SizedBox(width: 8.0), // Регулируйте отступы здесь
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: AppLocale.readAndAgree.getString(context),
                  style: TextStyle(
                    color: customColors.weakTextColor?.withAlpha(80),
                    fontSize: 12,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      setState(() {
                        agreeProtocol = !agreeProtocol;
                      });
                    },
                ),
                TextSpan(
                  text: '《${AppLocale.userTerms.getString(context)}》',
                  style: TextStyle(
                    color: customColors.linkColor?.withAlpha(150),
                    fontSize: 12,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(
                        Uri.parse('$apiServerURL/public/info/terms-of-user'),
                      );
                    },
                ),
                TextSpan(
                  text: AppLocale.andWord.getString(context),
                  style: TextStyle(
                    color: customColors.weakTextColor?.withAlpha(80),
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: '《${AppLocale.privacyPolicy.getString(context)}》',
                  style: TextStyle(
                    color: customColors.linkColor?.withAlpha(150),
                    fontSize: 12,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(
                        Uri.parse('$apiServerURL/public/info/privacy-policy'),
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThirdPartySignInButtons(
      BuildContext context, CustomColors customColors) {
    // return SizedBox(
    //   width: 250,
    //   child: SignInWithAppleButton(
    //     text: AppLocale.signInWithApple.getString(context),
    //     borderRadius: BorderRadius.circular(8),
    //     height: 40,
    //     onPressed: onAppleSigninSubmit,
    //   ),
    // );

    return Column(
      children: [
        Text(
          'Другие способы входа.',
          style: TextStyle(
            fontSize: 13,
            color: customColors.weakTextColor?.withAlpha(80),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                SignInButton(
                  Buttons.appleDark,
                  mini: true,
                  shape: const CircleBorder(),
                  onPressed: onAppleSigninSubmit,
                ),
                // const Text(
                //   '使用 Apple 账号登录',
                //   style: TextStyle(fontSize: 12),
                // )
              ],
            ),
            // const SizedBox(width: 40),
            // Column(
            //   children: [
            //     SignInButtonBuilder(
            //       backgroundColor: Colors.white,
            //       height: 25,
            //       onPressed: () async {
            //         await widget.settings.set(settingUsingGuestMode, "true");
            //         if (context.mounted) {
            //           context.push('/setting/openai-custom');
            //         }
            //       },
            //       text: AppLocale.useAsClient.getString(context),
            //       mini: true,
            //       shape: const CircleBorder(),
            //       image: ClipRRect(
            //         borderRadius: BorderRadius.circular(100),
            //         child: Image.asset('assets/openai.png'),
            //       ),
            //     ),
            //     const Text(
            //       '仅作为 OpenAI 客户端',
            //       style: TextStyle(fontSize: 12),
            //     ),
            //   ],
            // ),
          ],
        ),
      ],
    );
  }

  bool processing = false;

  onAppleSigninSubmit() async {
    if (processing) {
      return;
    }

    if (!agreeProtocol) {
      showErrorMessage(AppLocale.pleaseReadAgreeProtocol.getString(context));
      return;
    }

    processing = true;

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'cc.aicode.askaide',
          redirectUri: Uri.parse(
              'https://ai-api.aicode.cc/v1/callback/auth/sign_in_with_apple'),
        ),
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      APIServer()
          .signInWithApple(
        userIdentifier: credential.userIdentifier ?? '',
        authorizationCode: credential.authorizationCode,
        identityToken: credential.identityToken,
        familyName: credential.familyName,
        givenName: credential.givenName,
        email: credential.email,
      )
          .then((value) async {
        await widget.settings.set(settingAPIServerToken, value.token);
        await widget.settings.set(settingUserInfo, jsonEncode(value));

        HttpClient.cacheManager.clearAll().then((_) {
          if (value.needBindPhone) {
            if (context.mounted) {
              context.push('/bind-phone').then((value) async {
                if (value == 'logout') {
                  await widget.settings.set(settingAPIServerToken, '');
                  await widget.settings.set(settingUserInfo, '');
                }
              });
            }
            return;
          } else {
            context.go(
                '/chat-chat?show_initial_dialog=${value.isNewUser ? "true" : "false"}&reward=${value.reward}');
          }
        });
      }).catchError((e) {
        Logger.instance.e(e);
        showErrorMessage(AppLocale.signInFailed.getString(context));
      }).onError((error, stackTrace) {
        Logger.instance.e(error);
        showErrorMessage(AppLocale.signInFailed.getString(context));
      });
    } finally {
      processing = false;
    }
  }

  onSigninSubmit() {
    FocusScope.of(context).requestFocus(FocusNode());

    if (processing) {
      return;
    }

    final username = _usernameController.text.trim();
    if (username == '') {
      showErrorMessage(AppLocale.accountRequired.getString(context));
      return;
    }

    if (!phoneNumberValidator.hasMatch(username)) {
      showErrorMessage(AppLocale.accountFormatError.getString(context));
      return;
    }

    if (!agreeProtocol) {
      showErrorMessage(AppLocale.pleaseReadAgreeProtocol.getString(context));
      return;
    }

    processing = true;

    APIServer().checkPhoneExists(username).then((resp) async {
      context.push(
          '/signin-or-signup?username=$username&is_signup=${resp.exist ? "false" : "true"}&sign_in_method=${resp.signInMethod}');
    }).catchError((e) {
      showErrorMessage(resolveError(context, e));
    }).whenComplete(() => processing = false);
  }
}
