# encoding: utf-8

require "tieba_downloader/version"

module TiebaDownloader

	require 'open-uri'
	require 'nokogiri'
	require 'fileutils'
	require 'digest/md5'
	require 'base64'

	class Downloader

		def self.download(id, path, options)
			op_only = options[:op_only] || false
			caching = options[:caching] || false

			path = File.expand_path(path)

			puts "下载 #{id} 至 #{path}#{op_only ? '，只看楼主' : ''}"

      cached_doc = Nokogiri::HTML(read_url(page_url(id, 1, op_only), true)) if cached?(page_url(id, 1, op_only))
			doc = Nokogiri::HTML(read_url(page_url(id, 1, op_only), false))

      cached_pn = get_page_num(cached_doc) if cached_doc
			pn = get_page_num(doc)

			puts "共有 #{pn} 页"

			out_doc = template

			1.upto(pn) do |p|
				puts "正在下载页面 (%03d / %03d)" % [p, pn]
				url = page_url(id, p, op_only)
				doc = Nokogiri::HTML(read_url(url, caching && (p != cached_pn))) unless p == 1

				if p == 1
					base_node = Nokogiri::XML::Node.new('base', out_doc)
					base_node['href'] = url
					out_doc.at_css('head') << base_node
				end

				doc.css('div.left_section > div.core_title_wrap').each { |c| out_doc.at_css('div.left_section') << c } if p == 1
				doc.css('div.left_section > div.p_postlist').each { |c| out_doc.at_css('div.left_section') << c }
			end

			embed_css(out_doc)
			embed_img(out_doc, page_url(id, 1, op_only))

			IO.write(path, out_doc.to_s)
		end

		private

			def self.embed_css(doc)
				count = 0
				all = 0

				doc.css('link').each do |s|
					next unless s['rel'] == 'stylesheet'
					all += 1
				end

				doc.css('link').each do |s|
					next unless s['rel'] == 'stylesheet'

					count += 1
					puts "正在下载样式 (%03d / %03d)" % [count, all]

					css = read_url(s['href'], true)

					node = Nokogiri::XML::Node.new 'style', doc
					node.content = css
					s.add_next_sibling(node)

					s.remove
				end
			end

			def self.embed_img(doc, base)
				count = 0
				all = doc.css('img').size

				doc.css('img').each do |i|
					count += 1

					puts "正在下载图片 (%03d / %03d)" % [count, all]

					url = i['src']
					url = URI::join(base, url).to_s unless url.start_with? 'http'

					begin
						image = read_url(url, true, true)
						string = 'data:image/png;base64,' + Base64.strict_encode64(image).strip

						i['src'] = string
					rescue
						puts "  图片嵌入失败"
					end
				end
			end

			def self.page_url(id, page, op_only)
				"http://tieba.baidu.com/p/#{id}?pn=#{page}&see_lz=#{op_only ? 1 : 0}"
			end

			def self.get_page_num(doc)
				doc.css('li.l_reply_num span.red').last.content.to_i
			end

			def self.template()
				html = <<EOS
<html>
	<head>
		<style>header,footer,section,article,aside,nav,figure{display:block;margin:0;padding:0;border:0;}</style><link rel="shortcut icon" href="http://static.tieba.baidu.com/tb/favicon.ico" /><link rel="canonical" href="http://tieba.baidu.com/p/2129409225?see_lz=1&pn=5"/>
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??tb/static-common/style/tb_ui_ee1a9df0.css,tb/static-common/style/tb_common_f7f918b.css" />
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??/tb/_/padstyle_f62f0e6.css,/tb/_/top_banner_f7efdfb.css,/tb/_/mobile_tip_a4032eb.css,/tb/_/poptip_f81e5f1.css,/tb/_/ban_d89ad8da.css,/tb/_/search_dialog_911a0201.css,/tb/_/search_bright_918d1a5c.css,/tb/_/tope_092d64c2.css,/tb/_/comtrial_7121884.css,/tb/_/bright_f8c7e6d.css,/tb/_/padstyle_nav_30529717.css,/tb/_/tbnav_bright_ad3efb41.css,/tb/_/pager_f776b365.css,/tb/_/share_77e3e5d8.css,/tb/_/message_c781cea1.css,/tb/_/block_user_3741e120.css,/tb/_/admin_f71194e.css,/tb/_/toFrs_b2392e3f.css,/tb/_/threadInfo_e162c651.css,/tb/_/favthread_782e9f2f.css,/tb/_/forumTitle_3794e854.css,/tb/_/user_head_d42abf21.css,/tb/_/card_4ba3bfd4.css,/tb/_/user_a96c1845.css,/tb/_/icons_7843c0a9.css,/tb/_/url_check_370e11f8.css,/tb/_/yingyin_url_tip_type1_f6e6207b.css,/tb/_/yingyin_url_tip_type2_0a611e9d.css,/tb/_/prison_14befb45.css,/tb/_/js_pager_baf8f687.css" />
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??/tb/_/props_api_a7ddce6.css,/tb/_/residual_38d9843.css,/tb/_/posts_0b0751ff.css,/tb/_/bd_share_25899ff.css,/tb/_/share_thread_32d2da62.css,/tb/_/repost_2b418149.css,/tb/_/slide_show_f14bfedb.css,/tb/_/meizhi_slide_window_5731905d.css,/tb/_/platforum_activity_thread_dd92de05.css,/tb/_/pic_act_wall_d703167b.css,/tb/_/follower_abc5ca54.css,/tb/_/pic_act_poster_17dd50f8.css,/tb/_/platform_pic_act_thread_6f036f39.css,/tb/_/platforum_activity_repost_af3ca96e.css,/tb/_/idisk_6936707f.css,/tb/_/lzl_thread_forbidden_tip_b58a5cda.css,/tb/_/related_threads_inside_d4f303de.css,/tb/_/game_spread_thread_76cb4f06.css,/tb/_/inner_game_300b398c.css,/tb/_/forumListV3_8b3f1a20.css,/tb/_/voice_8653784c.css,/tb/_/meizhi_vote_39648ab.css,/tb/_/fancard_7279a9d4.css,/tb/_/interaction_892ea52.css,/tb/_/grade_1d9b075c.css,/tb/_/user_visit_card_a371894.css,/tb/_/thread_forbidden_tip_4d62bc1.css,/tb/_/editor_pic_meizhi_bff1e29a.css,tb/static-postor/widget/meizhi_postor/meizhi_postor_859f9109.css,/tb/_/rich_rank_5615444.css" />
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??/tb/_/sign_mod_ce0d4a67.css,/tb/_/sign_mod_bright_c7089f7c.css,/tb/_/loginForm_6d19387.css,/tb/_/initiative_for_score_1f7fe9e4.css,/tb/_/card_e0fc02eb.css,/tb/_/like_tip_adc12c53.css,/tb/_/tb_region_eecb81b.css,/tb/_/tb_spam_c1ea890e.css,/tb/_/balv_f678d46d.css,/tb/_/fan_aside_29d4fb0b.css,/tb/_/platform_aside_switch_8d3dee9.css,/tb/_/basket_lottery_ea3d29b.css,/tb/_/lecai_lottery_676a6e3.css,/tb/_/ssq_lottery_50349a8.css,/tb/_/lucky_lottery_5af2308.css,/tb/_/lottery_wrapper_2e8df4e.css,/tb/_/history_game_2ef120a.css,/tb/_/asidead_3698bf1.css,/tb/_/cpro_9b96a187.css,/tb/_/notice_ee5304b1.css,/tb/_/news_recommend_2a1306b.css,/tb/_/rank_82fe17f.css,/tb/_/top10_27beb804.css,/tb/_/thread_footer_d93a042.css,/tb/_/rich_ueditor_9cd614da.css,/tb/_/word_limit_881bfc9a.css,/tb/_/like_tip_adc12c53.css,/tb/_/rich_poster_6f2f28e5.css,/tb/_/editor_40e0faa4.css,tb/static-postor/widget/simple_postor/simple_postor_fd47c7b9.css" />
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??/tb/_/go_top_5ea1332.css,/tb/_/music_player_9552453b.css,/tb/_/noAutoVideo_6fd37ce.css,/tb/_/follow_be775ecf.css,/tb/_/nav_2aa281f3.css,/tb/_/skin_ad_8d47d76.css,/tb/_/dl_bubble_93f19946.css,/tb/_/magic_props_8fc3773.css,/tb/_/guide_11ff562.css,/tb/_/feedback_16ef2cf.css,/tb/_/guide_login_register_41d0822.css,/tb/_/tablegame_ca7578f.css,/tb/_/bright_9273507.css" />
	</head>

	<body>
		<div class="left_section" style="float: none; margin: 0 auto; ">
		</div>
	</body>
</html>
EOS

				html = Nokogiri::HTML(html)
				# html.encoding = 'gbk'

				html
			end

			def self.read_url(url, cached = false, skip_encoding = false)
				cache_dir = '/tmp/url_caches'

				FileUtils.mkdir_p(cache_dir)

				path = File.join(cache_dir, Digest::MD5.hexdigest(url))
        fresh = open(url).read unless (cached && File.exists?(path))
				File.write(path, open(url).read) unless File.exists?(path)

				cached ?
          sanitary_read(File.open(path), skip_encoding) :
          fresh
			end

      def self.cached?(url)
        cache_dir = '/tmp/url_caches'

        File.exists?(File.join(cache_dir, Digest::MD5.hexdigest(url)))
      end

			def self.sanitary_read(file, skip_encoding = false)
				skip_encoding ?
					file.read :
					file.read.encode('utf-8', 'gbk', undef: :replace, invalid: :replace, replace: '?')
			end

			def to_utf8(_string)
			    cd = CharDet.detect(_string)      #用于检测编码格式  在gem rchardet9里
			    if cd.confidence > 0.6
			      _string.force_encoding(cd.encoding)
			    end
			    _string.encode!("utf-8", :undef => :replace, :invalid => :replace, :replace => "?")
			    return _string
			end
	end

end

