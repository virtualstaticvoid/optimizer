require 'gsl'
require File.join(File.dirname(__FILE__), 'enumerable')

include GSL
include GSL::MultiMin

class DataItem
  
  attr_reader :date
  attr_reader :portfolio_return
  attr_reader :factor_returns
  
  def initialize(date, portfolio_return, factor_returns = [])
    @date = date
    @portfolio_return = portfolio_return
    @factor_returns = factor_returns
  end
  
  def residual(weights)
    raise "same number of weights as factor returns required" unless weights.length == factor_returns.length

    sum_product(weights) - portfolio_return
  end

  def sum_product(weights = [])
    raise "same number of weights as factor returns required" unless weights.length == factor_returns.length
    
    result = 0
    i = 0
    while i < factor_returns.length
      result += factor_returns[i] * weights[i]
      i += 1
    end
    result
  end
  
end

class WeightsOptimizer

  attr_reader :sample_size
  attr_reader :max_iterations

  def initialize(sample_size = 24, max_iterations = 100)
    @sample_size = sample_size
    @max_iterations = max_iterations
  end

  def optimize(data, num_factors)
    raise "not enough data points" unless data.length >= sample_size

    offset = 0
    results = []
  
    begin 
      # rolling sample 
      sample = data.slice(offset, sample_size)
      results << optimize_sample(sample, num_factors)
      offset += 1
    end while offset < (data.length - sample_size)

    results
  end
  
  private

  def optimize_sample(data, num_factors)

    # TODO: needs to ensure constraints:
    #  - objective >= 0
    #  - weights.count {|i| i < 0 || i > 1 } == 0
    #  - weights.sum == 1
  
    objective = Proc.new { |weights, data| 
      data.map { |pt| pt.residual(weights.to_a) }.standard_deviation
    }

    objective_func = GSL::MultiMin::Function.alloc(objective, num_factors)
    objective_func.set_params(data)

    # starting point
    starting_weights = GSL::Vector.alloc(num_factors)
    starting_weights.set_all(1.0 / num_factors)
    
    # step size
    step_size = GSL::Vector.alloc(num_factors)
    step_size.set_all(0.1)

    minimizer = GSL::MultiMin::FMinimizer.alloc("nmsimplex", num_factors)
    minimizer.set(objective_func, starting_weights, step_size)

    iter = 0
    begin
      iter += 1
      minimizer.iterate()
      status = minimizer.test_size(1e-2)

      ### begin debug output

        if status == GSL::SUCCESS
          puts("converged to minimum at")
        end
        x = minimizer.x
        printf("%5d ", iter);
        for i in 0...num_factors do
          printf("%10.3f ", x[i])
        end
        printf("f() = %7.3f size = %.3f  sum(weights) = %7.3f\n", minimizer.fval, minimizer.size, x.to_a.sum);

      ### end debug output
  
    end while status == GSL::CONTINUE and iter < max_iterations

    if status == GSL::SUCCESS
      [data[0].date, minimizer.fval, minimizer.x.to_a]
    else
      [data[0].date, nil, nil]
    end
  end

end

##
# sample data
##

data = [
  DataItem.new(Date.new(2004,10,31), 0.0795, [0.0204,-0.0867290329598607,0.0620842060449733,0.0853714382358282]),
  DataItem.new(Date.new(2004,11,30), 0.1144, [0.0852999999999999,0.0156746906154341,0.0851988305197289,0.132934378334963]),
  DataItem.new(Date.new(2004,12,31), 0.0455, [0.0257000000000001,-0.0399774840805414,0.046572366373697,0.0497716912499091]),
  DataItem.new(Date.new(2005,1,31), 0.0101, [0.00760000000000005,0.0416300205218412,-0.00568537293296767,-0.0254782422484205]),
  DataItem.new(Date.new(2005,2,28), 0.0335, [0.0454000000000001,0.112557463176658,0.0531968191018082,0.0412989048344379]),
  DataItem.new(Date.new(2005,3,31), -0.0147, [-0.0183,0.00805312532939806,-0.0042174301143062,-0.0544399475782417]),
  DataItem.new(Date.new(2005,4,30), -0.0216, [-0.0352,-0.086569630047891,-0.0505441897893251,-0.0176959991641245]),
  DataItem.new(Date.new(2005,5,31), 0.0712, [0.0791999999999999,0.165394081620972,0.0547971332168793,0.0673763188581378]),
  DataItem.new(Date.new(2005,6,30), 0.022, [0.0319,0.0245179415144938,0.0263259330476757,0.0182080668386857]),
  DataItem.new(Date.new(2005,7,31), 0.0897, [0.0787,0.0504511069137765,0.0780138938693706,0.0982040522706076]),
  DataItem.new(Date.new(2005,8,31), 0.0253, [0.0214000000000001,0.0291162001077025,0.00553052066566351,0.0343799273426928]),
  DataItem.new(Date.new(2005,9,30), 0.0456, [0.0891999999999999,0.161320076983796,0.099594377994952,0.0947278818692847]),
  DataItem.new(Date.new(2005,10,31), -0.0198, [-0.0284999999999999,-0.0286467084160684,-0.0363486727011088,-0.0423181944054347]),
  DataItem.new(Date.new(2005,11,30), 0.031, [0.0281,0.0297667251098759,0.0396572497591066,0.0490374895406276]),
  DataItem.new(Date.new(2005,12,31), 0.0602, [0.0881000000000001,0.0718152319144874,0.0787909879554827,0.0641820371322552]),
  DataItem.new(Date.new(2006,1,31), 0.0853, [0.0907,0.118961967787664,0.0751621278305139,0.118337808618339]),
  DataItem.new(Date.new(2006,2,28), 0.0064, [-0.0231,-0.0749995225393268,-0.00807299171427567,-0.0299249124108271]),
  DataItem.new(Date.new(2006,3,31), 0.055, [0.0693999999999999,0.0900275292498278,0.0913712902283619,0.0921609775410208]),
  DataItem.new(Date.new(2006,4,30), 0.0292, [0.0264,0.0812471192882984,0.0202433747082664,0.025417020244852]),
  DataItem.new(Date.new(2006,5,31), -0.0215, [-0.0446,0.018557772600132,-0.0499286664351599,-0.0484395207222621]),
  DataItem.new(Date.new(2006,6,30), 0.0016, [0.0153000000000001,0.101417785090611,0.027201721530971,0.0525846444223079]),
  DataItem.new(Date.new(2006,7,31), 0.0083, [-0.00860000000000016,-0.0490898775225515,-0.00546263574644412,-0.0327316167772452]),
  DataItem.new(Date.new(2006,8,31), 0.0478, [0.0511999999999999,0.0560688832203891,0.083235319314201,0.0821169106870905]),
  DataItem.new(Date.new(2006,9,30), 0.0228, [0.0208999999999999,0.0024931451466601,0.0206044864929067,-0.000694030736088092]),
  DataItem.new(Date.new(2006,10,31), 0.0411, [0.0540000000000001,0.034181272943488,0.051962740770042,0.0423919913850452]),
  DataItem.new(Date.new(2006,11,30), 0.0378, [0.0369999999999999,0.0104139065398132,0.0916729027457273,0.060678625872588]),
  DataItem.new(Date.new(2006,12,31), 0.0523, [0.0557000000000001,-0.0000989589518267664,0.0697958587779062,0.0418828248370735]),
  DataItem.new(Date.new(2007,1,31), 0.0436, [0.0316000000000001,0.00644286534312455,0.0551470641656913,0.0527398737498011]),
  DataItem.new(Date.new(2007,2,28), 0.0077, [0.0134000000000001,0.0294808885567346,-0.00169298223166547,0.0039013895947948]),
  DataItem.new(Date.new(2007,3,31), 0.06, [0.0589999999999999,0.111170014614437,0.0245796715035465,0.0656064518543364]),
  DataItem.new(Date.new(2007,4,30), 0.0417, [0.0466,-0.00592712940397744,0.076571479858774,0.0427278288149202]),
  DataItem.new(Date.new(2007,5,31), 0.0197, [-0.00190000000000001,0.0661838464199238,-0.0141186561130613,0.0266335649997149]),
  DataItem.new(Date.new(2007,6,30), -0.0016, [-0.0177000000000001,0.00810261692627745,-0.0196781899890535,-0.0171905193304726]),
  DataItem.new(Date.new(2007,7,31), -0.0064, [0.00459999999999994,0.0123217410543677,-0.0121544980735988,-0.00023690149267519]),
  DataItem.new(Date.new(2007,8,31), -0.0024, [0.0081,-0.00544013860630721,0.00216375253328072,0.0015092133562995]),
  DataItem.new(Date.new(2007,9,30), 0.0287, [0.0301,0.127190055897618,-0.0114141572590283,0.0789469324148269]),
  DataItem.new(Date.new(2007,10,31), 0.0458, [0.0681000000000001,0.0134556488203268,0.059292103418624,0.0994334644297163]),
  DataItem.new(Date.new(2007,11,30), -0.0253, [-0.0331,-0.0272605173692236,-0.0386531627902867,-0.0561422850001753]),
  DataItem.new(Date.new(2007,12,31), -0.0259, [-0.0354,-0.0618379513436936,-0.0139286879407138,0.0190471389261706]),
  DataItem.new(Date.new(2008,1,31), -0.0765, [-0.0701000000000001,0.0320754572352788,-0.123767380396611,-0.106084646154256]),
  DataItem.new(Date.new(2008,2,29), 0.0858, [0.1094,0.177822752845498,0.0811962312692249,0.187186644359004]),
  DataItem.new(Date.new(2008,3,31), -0.0048, [-0.0341,-0.0329728536746855,-0.0157789649864853,0.00475220686671563]),
  DataItem.new(Date.new(2008,4,30), 0.0441011878542761, [0.0391999999999999,0.0486417225279741,-0.00574464922773343,0.0583836043571819]),
  DataItem.new(Date.new(2008,5,31), 0.0386, [0.0281,0.0674313110365605,-0.0235399297153829,0.0808675602278666]),
  DataItem.new(Date.new(2008,6,30), -0.0396, [-0.0656,0.0130374374852542,-0.0804172907678032,-0.0655705721069215]),
  DataItem.new(Date.new(2008,7,31), -0.0592, [-0.0505,-0.191055075547377,0.0517730700094521,-0.134235478180821]),
  DataItem.new(Date.new(2008,8,31), 0.0244, [0.0125999999999999,-0.0237962373865724,0.0534208078414769,0.016657345261919]),
  DataItem.new(Date.new(2008,9,30), -0.1372, [-0.1049,-0.218920670521241,-0.0756481926449197,-0.140751593589544]),
  DataItem.new(Date.new(2008,10,31), -0.0873, [-0.1192,-0.169905605407295,-0.0538821027577877,-0.204054524870222]),
  DataItem.new(Date.new(2008,11,30), -0.0308, [0.00869999999999993,0.0512028572070353,-0.0261922937664319,-0.0443118023421448]),
  DataItem.new(Date.new(2008,12,31), 0.0246, [0.0298,-0.00218489908864605,0.0665021349053556,0.0697945825748914]),
  DataItem.new(Date.new(2009,1,31), -0.0283025402538776, [-0.0472,-0.0262976149048371,-0.0472374133745195,0.0193064450992955]),
  DataItem.new(Date.new(2009,2,28), -0.0754, [-0.0947000000000001,-0.0883033765319755,-0.10404185481598,-0.0829293699561793]),
  DataItem.new(Date.new(2009,3,31), 0.0679, [0.106,0.145477133879732,0.0963317989042531,0.0209526775392797]),
  DataItem.new(Date.new(2009,4,30), 0.0235, [0.0237000000000001,-0.0300734461789559,0.0530002261905833,-0.0108633533374126]),
  DataItem.new(Date.new(2009,5,31), 0.0717, [0.0864,0.163747197689756,0.0549143272241641,0.101170379641806]),
  DataItem.new(Date.new(2009,6,30), -0.0012, [-0.0134,-0.0902005233477463,0.0280367098980765,0.0139515870048283]),
  DataItem.new(Date.new(2009,7,31), 0.0826, [0.0899000000000001,0.0980666594890567,0.0836025401686547,0.080806518968491]),
  DataItem.new(Date.new(2009,8,31), 0.0419, [0.0408999999999999,0.0181997301322725,0.0692613491295007,0.0309868236345547]),
  DataItem.new(Date.new(2009,9,30), 0.019, [0.00390000000000001,-0.00556225553359602,0.0117457163619559,0.0312865977449301]),
  DataItem.new(Date.new(2009,10,31), 0.0416, [0.0444,0.074793418916925,0.043447479923018,0.0412230243969292]),
  DataItem.new(Date.new(2009,11,30), -0.0155, [0.00459999999999994,0.0589229633951707,0.0000380465097142846,0.0110340364093717]),
  DataItem.new(Date.new(2009,12,31), 0.0389, [0.0386,0.0251967036439806,0.0376000000000001,0.0610999999999999]),
  DataItem.new(Date.new(2010,1,31), -0.0231, [-0.0262,-0.0640696815090283,-0.0208,-0.0255]),
  DataItem.new(Date.new(2010,2,28), 0.0241, [0.0101,-0.00984693338963372,0.0212000000000001,0.0264]),
  DataItem.new(Date.new(2010,3,31), 0.0524, [0.0691999999999999,0.101678941375649,0.0646,0.0832999999999999]),
  DataItem.new(Date.new(2010,4,30), -0.0064, [0.00580000000000003,-0.0163624117428465,0.00910000000000011,-0.00180000000000002]),
  DataItem.new(Date.new(2010,5,31), -0.034993, [-0.0444,-0.0649524416687328,-0.0305,-0.0474000000000001]),
  DataItem.new(Date.new(2010,6,30), -0.0268, [-0.0327999999999999,-0.0418048517701722,-0.0399,-0.0381]),
  DataItem.new(Date.new(2010,7,31), 0.075602199993895, [0.0838000000000001,0.0594981354674069,0.0686,0.1015]),
  DataItem.new(Date.new(2010,8,31), -0.0259, [-0.0302,-0.0625246147659577,-0.021,-0.0423]),
  DataItem.new(Date.new(2010,9,30), 0.0849359, [0.0876999999999999,0.078431025714728,0.083,0.1207]),
  DataItem.new(Date.new(2010,10,31), 0.0376634776030265, [0.0235000000000001,0.0854386130372204,0.0209999999999999,0.0243])
]

# perform optimization

results = WeightsOptimizer.new().optimize(data, 4)

# output results

puts '   date       R       f1      f2      f3      f4'
puts '----------------------------------------------------'
results.each do |result|

  # date
  printf(result[0].to_s)
  
  # minimum
  printf("%7.3f ", result[1])
  
  # weights
  result[2].to_a.each do |weight|
    printf("%7.3f ", weight)
  end
  
  printf("\n")
end

