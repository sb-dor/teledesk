class PaginationUtil {
  final int _paginationPerPage = 20;

  int checkIsListHasMorePageInt<T>({required List<T> list, required int page, int? limitInPage}) {
    if (list.length < (limitInPage ?? _paginationPerPage)) {
      page = 1;
    } else {
      page++;
    }
    return page;
  }

  //this fun will check is there more list in pag (returns boolean)
  bool checkIsListHasMorePageBool<T>({required List<T> list, int? limitInPage}) {
    if (list.length < (limitInPage ?? _paginationPerPage)) {
      return false;
    } else {
      return true;
    }
  }
}
