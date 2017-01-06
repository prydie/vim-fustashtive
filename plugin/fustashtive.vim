function! s:function(name) abort
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
endfunction

function! s:bitbucket_server_url(opts, ...) abort
  if a:0 || type(a:opts) != type({})
    return ''
  endif
  let path = substitute(a:opts.path, '^/', '', '')
  if !exists('g:fugitive_bitbucket_server_domains')
    return ''
  endif
  let domains = g:fugitive_bitbucket_server_domains
  let domain_patterns = deepcopy(domains)
  map(domain_patterns, { index, domain -> escape(split(domain, '://')[-1], '.') })
  let domain_pattern = join(domain_patterns, '\|')
  let repo = matchstr(a:opts.remote,'^\%(https\=://\|git://\|\(ssh://\)\=git@\)\%(.\{-\}@\)\=\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=$')
  if repo ==# ''
    return ''
  endif
  let root = 'https://' . split(repo, '/')[0] . '/projects/' . toupper(split(repo, '/')[1]) . '/repos/' . split(repo, '/')[2]
  if path =~# '^\.git/refs/heads/'
    return root . '/commits/' . path[16:-1]
  elseif path =~# '^\.git/refs/tags/'
    return root . '/browse?at=' .path[5:-1]
  elseif path =~# '.git/\%(config$\|hooks\>\)'
    return root . '/settings'
  elseif path =~# '^\.git\>'
    return root
  endif
  if a:opts.commit =~# '^\d\=$'
    let commit = a:opts.repo.rev_parse('HEAD')
  else
    let commit = a:opts.repo.rev_parse(a:opts.commit)
  endif
  if get(a:opts, 'type', '') ==# 'tree' || a:opts.path =~# '/$'
    let url = root . '/browse/' . path . '?at=' . commit
  elseif get(a:opts, 'type', '') ==# 'blob' || a:opts.path =~# '[^/]$'
    let url = root . '/browse/' . path . '?at=' . commit
    if get(a:opts, 'line1')
      let url .= '#' . a:opts.line1
      if get(a:opts, 'line2')
        let url .= '-' . a:opts.line2
      endif
    endif
  else
    let url = root . '/commits/' . commit
  endif
  return url
endfunction

if !exists('g:fugitive_browse_handlers')
  let g:fugitive_browse_handlers = []
endif

call insert(g:fugitive_browse_handlers, s:function('s:bitbucket_server_url'))
