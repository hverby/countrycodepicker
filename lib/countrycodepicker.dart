library countrycodepicker;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sim_country_code/flutter_sim_country_code.dart';

part 'country.dart';
part 'functions.dart';

const TextStyle _defaultItemTextStyle = const TextStyle(fontSize: 16);
const TextStyle _defaultSearchInputStyle = const TextStyle(fontSize: 16);
const Color _defaultSearchCursorColor = Colors.black;
const String _kDefaultSearchHintText = 'Search country name, code';
const String countryCodePackageName = 'countrycodepicker';

class CountryPickerWidget extends StatefulWidget {
  /// This callback will be called on selection of a [Country].
  final ValueChanged<Country>? onSelected;

  /// [itemTextStyle] can be used to change the TextStyle of the Text in ListItem. Default is [_defaultItemTextStyle]
  final TextStyle? itemTextStyle;

  /// [searchInputStyle] can be used to change the TextStyle of the Text in SearchBox. Default is [searchInputStyle]
  final TextStyle searchInputStyle;
  final Color? searchCursorColor;
  final double? searchCursorHeight;
  final double searchCursorWidth;
  final Widget? searchSuffixIcon;
  final EdgeInsetsGeometry? searchPadding;
  final EdgeInsetsGeometry? listViewPadding;
  final Widget? loadingWidget;
  final double? searchBoxMarginTop;

  /// [searchInputDecoration] can be used to change the decoration for SearchBox.
  final InputDecoration? searchInputDecoration;

  /// Flag icon size (width). Default set to 32.
  final double flagIconSize;

  ///Can be set to `true` for showing the List Separator. Default set to `false`
  final bool showSeparator;

  ///Can be set to `true` for opening the keyboard automatically. Default set to `false`
  final bool focusSearchBox;

  ///This will change the hint of the search box. Alternatively [searchInputDecoration] can be used to change decoration fully.
  final String searchHintText;

  const CountryPickerWidget({
    Key? key,
    this.onSelected,
    this.itemTextStyle = _defaultItemTextStyle,
    this.searchInputStyle = _defaultSearchInputStyle,
    this.searchCursorColor = _defaultSearchCursorColor,
    this.searchCursorHeight,
    this.searchCursorWidth = 2.0,
    this.searchSuffixIcon,
    this.searchPadding,
    this.listViewPadding,
    this.loadingWidget,
    this.searchBoxMarginTop,
    this.searchInputDecoration,
    this.searchHintText = _kDefaultSearchHintText,
    this.flagIconSize = 32,
    this.showSeparator = false,
    this.focusSearchBox = false,
  }) : super(key: key);

  @override
  _CountryPickerWidgetState createState() => _CountryPickerWidgetState();
}

class _CountryPickerWidgetState extends State<CountryPickerWidget> {
  List<Country> _list = [];
  List<Country> _filteredList = [];
  TextEditingController _controller = new TextEditingController();
  ScrollController _scrollController = new ScrollController();
  bool _isLoading = false;
  Country? _currentCountry;

  void _onSearch(text) {
    if (text == null || text.isEmpty) {
      setState(() {
        _filteredList.clear();
        _filteredList.addAll(_list);
      });
    } else {
      setState(() {
        _filteredList = _list
            .where((element) =>
                element.name
                    .toLowerCase()
                    .contains(text.toString().toLowerCase()) ||
                element.callingCode
                    .toLowerCase()
                    .contains(text.toString().toLowerCase()) ||
                element.countryCode
                    .toLowerCase()
                    .startsWith(text.toString().toLowerCase()))
            .map((e) => e)
            .toList();
      });
    }
  }

  @override
  void initState() {
    _scrollController.addListener(() {
      FocusScopeNode currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus) {
        currentFocus.unfocus();
      }
    });
    loadList();
    super.initState();
  }

  void loadList() async {
    setState(() {
      _isLoading = true;
    });
    _list = await getCountries(context);
    try {
      String? code = await FlutterSimCountryCode.simCountryCode;
      _currentCountry =
          _list.firstWhere((element) => element.countryCode == code);
      final country = _currentCountry;
      if (country != null) {
        _list.removeWhere(
            (element) => element.callingCode == country.callingCode);
        _list.insert(0, country);
      }
    } catch (e) {
    } finally {
      setState(() {
        _filteredList = _list.map((e) => e).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: widget.searchBoxMarginTop ?? 16,
        ),
        Padding(
          padding: widget.searchPadding ?? EdgeInsets.only(left: 16, right: 16),
          child: TextField(
            style: widget.searchInputStyle,
            cursorColor: widget.searchCursorColor,
            cursorHeight: widget.searchCursorHeight,
            cursorWidth: widget.searchCursorWidth,
            autofocus: widget.focusSearchBox,
            decoration: widget.searchInputDecoration?.copyWith(
                  suffixIcon: Visibility(
                    visible: _controller.text.isNotEmpty,
                    child: IconButton(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      icon: widget.searchSuffixIcon ?? Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _controller.clear();
                        _filteredList.clear();
                        _filteredList.addAll(_list);
                      }),
                    ),
                  ),
                ) ??
                InputDecoration(
                  suffixIcon: Visibility(
                    visible: _controller.text.isNotEmpty,
                    child: IconButton(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      icon: widget.searchSuffixIcon ?? Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _controller.clear();
                        _filteredList.clear();
                        _filteredList.addAll(_list);
                      }),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                  hintText: widget.searchHintText,
                ),
            textInputAction: TextInputAction.done,
            controller: _controller,
            onChanged: _onSearch,
          ),
        ),
        SizedBox(
          height: 24,
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: widget.loadingWidget ?? CircularProgressIndicator())
              : ListView.separated(
                  padding: widget.listViewPadding ?? EdgeInsets.only(top: 16),
                  controller: _scrollController,
                  itemCount: _filteredList.length,
                  separatorBuilder: (_, index) =>
                      widget.showSeparator ? Divider() : Container(),
                  itemBuilder: (_, index) {
                    return InkWell(
                      onTap: () {
                        widget.onSelected?.call(_filteredList[index]);
                      },
                      child: Container(
                        padding: EdgeInsets.only(bottom: 16, left: 4),
                        child: Row(
                          children: <Widget>[
                            Image.asset(
                              _filteredList[index].flag,
                              package: countryCodePackageName,
                              width: widget.flagIconSize,
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            Expanded(
                                child: Text(
                              '${_filteredList[index].callingCode} ${_filteredList[index].name}',
                              style: widget.itemTextStyle,
                            )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
}