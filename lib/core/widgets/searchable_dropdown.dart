import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../network/providers.dart';
import '../constants/app_colors.dart';

class SearchableDropdown<T extends Object> extends ConsumerStatefulWidget {
  final String label;
  final String hintText;
  final String table;
  final T? Function(Map<String, dynamic> json) fromJson;
  final String Function(T item) displayStringForOption;
  final bool Function(T item, String query) searchFilter;
  final void Function(T? selected) onSelected;
  final String? initialValueId;
  final String idField;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.table,
    required this.fromJson,
    required this.displayStringForOption,
    required this.searchFilter,
    required this.onSelected,
    this.hintText = 'Buscar...',
    this.initialValueId,
    this.idField = 'id',
  });

  @override
  ConsumerState<SearchableDropdown<T>> createState() =>
      _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T extends Object>
    extends ConsumerState<SearchableDropdown<T>> {
  List<T> _items = [];
  bool _isLoading = false;
  T? _selectedItem;
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getEntity(widget.table);
      if (mounted) {
        setState(() {
          _items = data.map((e) => widget.fromJson(e)).whereType<T>().toList();

          if (widget.initialValueId != null &&
              widget.initialValueId!.isNotEmpty) {
            try {
              _selectedItem = _items.firstWhere((item) {
                final Map<String, dynamic> json = (item as dynamic).toJson();
                return json[widget.idField] == widget.initialValueId;
              });
              if (_selectedItem != null) {
                _textEditingController.text = widget.displayStringForOption(
                  _selectedItem as T,
                );
              }
            } catch (e) {
              // Not found
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching for SearchableDropdown: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : Autocomplete<T>(
                displayStringForOption: widget.displayStringForOption,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return <T>[].where((T option) => false);
                  }
                  return _items.where((T option) {
                    return widget.searchFilter(option, textEditingValue.text);
                  });
                },
                onSelected: (T selection) {
                  setState(() => _selectedItem = selection);
                  widget.onSelected(selection);
                },
                fieldViewBuilder:
                    (
                      BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      if (_selectedItem == null &&
                          _textEditingController.text.isEmpty &&
                          widget.initialValueId == null) {
                        fieldTextEditingController.text = '';
                      } else if (_selectedItem != null) {
                        fieldTextEditingController.text = widget
                            .displayStringForOption(_selectedItem as T);
                      } else {
                        fieldTextEditingController.text =
                            _textEditingController.text;
                      }

                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        onChanged: (val) {
                          if (val.isEmpty) {
                            setState(() => _selectedItem = null);
                            widget.onSelected(null);
                          }
                        },
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          maxWidth: MediaQuery.of(context).size.width - 32,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final T option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  widget.displayStringForOption(option),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
