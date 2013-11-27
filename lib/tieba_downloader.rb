# encoding: utf-8

require "tieba_downloader/version"

module TiebaDownloader

	require 'open-uri'
	require 'nokogiri'
	require 'fileutils'
	require 'digest/md5'

	class Downloader

		def self.download(id, path, options)
			op_only = options[:op_only] || false
			caching = options[:caching] || false

			path = File.expand_path(path)

			puts "下载 #{id} 至 #{path}#{op_only ? '，只看楼主' : ''}"

			doc = Nokogiri::HTML(read_url(page_url(id, 1, op_only), caching))

			pn = get_page_num(doc)

			puts "共有 #{pn} 页"

			out_doc = template

			1.upto(pn) do |p|
				puts "正在下载第 %03d / %03d 页" % [p, pn]
				url = page_url(id, p, op_only)
				doc = Nokogiri::HTML(read_url(url, caching)) unless p == 1

				if p == 1
					base_node = Nokogiri::XML::Node.new('base', out_doc)
					base_node['href'] = url
					out_doc.at_css('head') << base_node 
				end

				doc.css('div.core > div.core_title_wrap').each { |c| out_doc.at_css('div.core') << c } if p == 1
				doc.css('div.core > div.p_postlist').each { |c| out_doc.at_css('div.core') << c }
			end

			IO.write(path, out_doc.to_s)
		end

		private

			def self.page_url(id, page, op_only)
				"http://tieba.baidu.com/p/#{id}?pn=#{page}&see_lz=#{op_only ? 1 : 0}"
			end

			def self.get_page_num(doc)
				doc.css('li.l_reply_num span.red').first.content.to_i
			end

			def self.template()
				html = <<EOS
<html>
	<head>
		<style>header,footer,section,article,aside,nav,figure{display:block;margin:0;padding:0;border:0}</style><link rel="shortcut icon" href="http://static.tieba.baidu.com/tb/favicon.ico" /><link rel="canonical" href="http://tieba.baidu.com/p/2700295789"/>
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??tb/static-common/style/tb_ui_4bdeadcc.css,tb/static-common/style/tb_common_28aafcab.css" />
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??/tb/_/user_54cd1749.css,/tb/_/padstyle_93e3a02e.css,/tb/_/top_banner_f213977a.css,/tb/_/mobile_tip_8f903bd4.css,/tb/_/poptip_6f29b423.css,/tb/_/search_d0398cac.css,/tb/_/tope_092d64c2.css,/tb/_/comtrial_8f28f1d3.css,/tb/_/rich_f9159604.css,/tb/_/padstyle_nav_a9e5e732.css,/tb/_/nav_2aa281f3.css,/tb/_/tbnav_341679f0.css,/tb/_/imgLikeAction_1bcfe3e9.css,/tb/_/platform_skin_31d6cfe0.css,/tb/_/roll_number_f65729a2.css,/tb/_/cheerForGEFC_125cb565.css,/tb/_/platform_weal_c8f64fe7.css,/tb/_/platform_head_ad8d8d3c.css,/tb/_/navigation_b8c4492d.css,/tb/_/timeaxis_af743834.css,/tb/_/platform_gallery_e41b40cd.css,/tb/_/form_editor_6e1b12a9.css,/tb/_/star_head_78843316.css,/tb/_/pager_71519538.css,/tb/_/share_77e3e5d8.css,/tb/_/message_c781cea1.css,/tb/_/block_user_3741e120.css,/tb/_/admin_ec512558.css,/tb/_/toFrs_b2392e3f.css,/tb/_/threadInfo_0a70161a.css" />
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??/tb/_/favthread_20612eca.css,/tb/_/forumTitle_554ab95e.css,/tb/_/icons_d5da634a.css,/tb/_/url_check_370e11f8.css,/tb/_/yingyin_url_tip_type1_f6e6207b.css,/tb/_/yingyin_url_tip_type2_0a611e9d.css,/tb/_/prison_14befb45.css,/tb/_/posts_3ede6b69.css,/tb/_/bd_share_719f1f51.css,/tb/_/share_thread_7762ec34.css,/tb/_/repost_0d2fe80a.css,/tb/_/slide_show_f14bfedb.css,/tb/_/meizhi_slide_window_71fbf9d6.css,/tb/_/platforum_activity_thread_637c5c98.css,/tb/_/platforum_activity_repost_19d72ded.css,/tb/_/idisk_13215ff6.css,/tb/_/lzl_thread_forbidden_tip_b58a5cda.css,/tb/_/game_spread_thread_c3fdf46a.css,/tb/_/related_threads_inside_ff525d9c.css,/tb/_/forumListV3_6ca01c3e.css,/tb/_/card_e8514f4c.css,/tb/_/voice_df66233d.css,tb/static-encourage/component/meizhi_vote/meizhi_vote_1b996a32.css,/tb/_/fancard_8924e942.css,/tb/_/grade_b2030134.css,/tb/_/interaction_154d0bb2.css,/tb/_/user_visit_card_536aab1e.css,/tb/_/thread_forbidden_tip_30c4094f.css,/tb/_/editor_pic_meizhi_82dc9008.css,tb/static-postor/widget/meizhi_postor/meizhi_postor_419117c5.css" />
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??/tb/_/sign_mod_c7fd60d5.css,/tb/_/loginForm_d3a30496.css,/tb/_/initiative_for_score_8e8ef186.css,/tb/_/tb_region_c9856ac4.css,/tb/_/balv_f1e9dfd8.css,/tb/_/tb_spam_c1ea890e.css,/tb/_/fan_aside_6cd84a4d.css,/tb/_/platform_aside_switch_cfcf06f2.css,/tb/_/lecai_lottery_7c35820d.css,/tb/_/basket_lottery_1beeaf7c.css,/tb/_/lucky_lottery_48875540.css,/tb/_/history_game_778e5727.css,/tb/_/asidead_dadb72dc.css,/tb/_/comad_dfcc91c6.css,/tb/_/cpro_3f453949.css,/tb/_/notice_b458d27d.css,/tb/_/follower_abc5ca54.css,/tb/_/news_recommend_374a53ac.css,/tb/_/rank_63df50b8.css,/tb/_/top10_27beb804.css,/tb/_/rich_ueditor_448bd9e7.css,/tb/_/word_limit_881bfc9a.css,/tb/_/rich_poster_3eb7e12c.css,/tb/_/editor_40e0faa4.css,tb/static-postor/widget/simple_postor/simple_postor_fd47c7b9.css,/tb/_/go_top_f97f29b7.css,/tb/_/noAutoVideo_f8175432.css,/tb/_/follow_be775ecf.css,/tb/_/fantuan_floatlayer_fd910978.css,/tb/_/ten_years_5963a8ca.css" />
		<link rel="stylesheet" href="http://tb1.bdstatic.com/??/tb/_/dl_bubble_93f19946.css,/tb/_/skin_ad_37a07fe6.css,/tb/_/game_couplet_pb_d3b8be49.css,/tb/_/v3_02bfab3e.css" />
	</head>

	<body>
		<div class="core" style="margin: 0 auto; ">
		</div>
	</body>
</html>
EOS

				html = Nokogiri::HTML(html)
				# html.encoding = 'gbk'

				html
			end

			def self.read_url(url, cached = false)
				return open(url).read.encode('utf-8', 'gbk', undef: :replace, invalid: :replace, replace: '?') unless cached

				cache_dir = '/tmp/url_caches'

				FileUtils.mkdir_p(cache_dir)

				path = File.join(cache_dir, Digest::MD5.hexdigest(url))
				File.write(path, open(url).read) unless File.exists?(path)
				puts path
				File.open(path).read.encode('utf-8', 'gbk', undef: :replace, invalid: :replace, replace: '?')
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

