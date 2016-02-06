###
 # jQueryFileTree Plugin
 #
 # @author - Cory S.N. LaViska - A Beautiful Site (http://abeautifulsite.net/) - 24 March 2008
 # @author - Dave Rogers - https://github.com/daverogers/jQueryFileTree
 #
 # Usage: $('.fileTreeDemo').fileTree({ options }, callback )
 #
 # TERMS OF USE
 #
 # This plugin is dual-licensed under the GNU General Public License and the MIT License and
 # is copyright 2008 A Beautiful Site, LLC.
###

do($ = window.jQuery, window) ->
    # Define the plugin class
    class FileTree


        constructor: (el, args, callback) ->
            $el = $(el)
            defaults = {
                root: '/'
                script: '/files/filetree'
                folderEvent: 'click'
                expandSpeed: 500
                collapseSpeed: 500
                expandEasing: 'swing'
                collapseEasing: 'swing'
                multiFolder: true
                loadMessage: 'Loading...'
                errorMessage: 'Unable to get file tree information'
                multiSelect: false
                onlyFolders: false
                onlyFiles: false
            }
            @jqft = {
                container: $el # initiator element
            }
            @options = $.extend(defaults, args)
            @callback = callback

            # Loading message
            $el.html('<ul class="jqueryFileTree start"><li class="wait">' + @options.loadMessage + '<li></ul>')

            # Get the initial file list
            this.showTree( $el, escape(@options.root))
            
            # set delegate event handler for clicks
            $el.delegate "li a", @options.folderEvent, (event) =>
                $ev      = $(event.target)
                options  = @options
                jqft     = @jqft
                _this    = @
                callback = @callback

                # set up data object to send back via trigger
                data           = {}
                data.li        = $ev.closest('li')
                data.type      = ( data.li.hasClass('directory') ? 'directory' : 'file' )
                data.value     = $ev.text()
                data.rel       = $ev.prop('rel')
                data.container = jqft.container

                if $ev.parent().hasClass('directory')
                    if $ev.parent().hasClass('collapsed')
                        # Expand
                        _this._trigger($ev, 'filetreeexpand', data)

                        if !options.multiFolder
                            $ev.parent().parent().find('UL').slideUp({ duration: options.collapseSpeed, easing: options.collapseEasing })
                            $ev.parent().parent().find('LI.directory').removeClass('expanded').addClass('collapsed')

                        $ev.parent().removeClass('collapsed').addClass('expanded')
                        $ev.parent().find('UL').remove() # cleanup
                        _this.showTree $ev.parent(), $ev.attr('rel')

                        # return expanded event with data - in the future this really needs to go into the slideDown complete function
                        _this._trigger($ev, 'filetreeexpanded', data)
                    else
                        # Collapse
                        _this._trigger($ev, 'filetreecollapse', data)

                        $ev.parent().find('UL').slideUp({ duration: options.collapseSpeed, easing: options.collapseEasing })
                        $ev.parent().removeClass('expanded').addClass('collapsed')

                        _this._trigger($ev, 'filetreecollapsed', data)
                else
                    # this is a file click, return file information
                    if !options.multiSelect
                        # remove "selected" class if set, then append class to currently selected file
                        jqft.container.find('li').removeClass('selected')
                        $ev.parent().addClass('selected')
                    else
                        # since it's multiselect, more than one element can have the 'selected' class
                        if $ev.parent().find('input').is(':checked')
                            $ev.parent().find('input').prop('checked', false)
                            $ev.parent().removeClass('selected')
                        else
                            $ev.parent().find('input').prop('checked', true)
                            $ev.parent().addClass('selected')

                    _this._trigger($ev, 'filetreeclicked', data)

                    # perform return
                    callback? $ev.attr('rel')


        showTree: (el, dir) ->

            $el = $(el)
            options = @options
            _this = @

            $el.addClass('wait')
            $(".jqueryFileTree.start").remove()

            # do yo' voodoo magic white boy
            data =
                dir: dir
                onlyFolders: options.onlyFolders
                onlyFiles: options.onlyFiles
                multiSelect: options.multiSelect

            handleResult = (result) ->
                $el.find('.start').html('')
                $el.removeClass('wait').append(result)
                if options.root == dir
                    $el.find('UL:hidden').show( callback? )
                else
                    # ensure an easing library is loaded if custom easing is used
                    if jQuery.easing[options.expandEasing] == undefined
                        console.log 'Easing library not loaded. Include jQueryUI or 3rd party lib.'
                        options.expandEasing = 'swing' # revert to swing (default)
                    $el.find('UL:hidden').slideDown { duration: options.expandSpeed, easing: options.expandEasing }

                # if multiselect is on and the parent folder is selected, propagate check to child elements
                li = $('[rel="'+decodeURIComponent(dir)+'"]').parent()
                if options.multiSelect && li.children('input').is(':checked')
                    li.find('ul li input').each () ->
                        $(this).prop('checked', true)
                        $(this).parent().addClass('selected')
                return false;

            handleFail = () ->
                $el.find('.start').html('')
                $el.removeClass('wait').append("<p>"+options.errorMessage+"</p>")
                return false

            if typeof options.script is 'function'
                result = options.script(data)
                if typeof result is 'string' or result instanceof jQuery
                    handleResult(result)
                else
                    handleFail()
            else
                $.ajax
                    url: options.script
                    type: 'POST'
                    dataType: 'HTML'
                    data: data
                .done (result) ->
                    handleResult(result)
                .fail () ->
                    handleFail()
        # end showTree()

        # wrapper to append trigger type to data
        _trigger: (el, eventType, data) ->
            $el = $(el)
            $el.trigger(eventType, data)

    # Define the plugin
    $.fn.extend fileTree: (args, callback) ->
        @each ->
            $this = $(this)
            data = $this.data('fileTree')

            if !data
                $this.data 'fileTree', (data = new FileTree(this, args, callback))
            if typeof args == 'string'
                data[option].apply(data)
