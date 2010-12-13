require 'spec_helper'

describe RubyFlipper::Feature do

  describe 'initializer' do

    it 'should store the name' do
      RubyFlipper::Feature.new(:feature_name).name.should == :feature_name
    end

    it 'should work with a single static condition' do
      RubyFlipper::Feature.new(:feature_name, true).conditions.should == [true]
    end

    it 'should work with multiple static conditions' do
      RubyFlipper::Feature.new(:feature_name, true, :development).conditions.should == [true, :development]
    end

    it 'should work with a dynamic condition' do
      condition = lambda { true }
      RubyFlipper::Feature.new(:feature_name, condition).conditions.should == [condition]
    end

    it 'should work with a combination of static and dynamic conditions' do
      condition = lambda { true }
      RubyFlipper::Feature.new(:feature_name, false, :live, condition).conditions.should == [false, :live, condition]
    end

    it 'should work with a combination of arrays and eliminate nil' do
      condition = lambda { true }
      RubyFlipper::Feature.new(:feature_name, [false, nil], condition).conditions.should == [false, condition]
    end

  end

  describe '#active?' do

    it 'should return false when not all conditions are met (with dynamic)' do
      RubyFlipper::Feature.new(:feature_name, true, lambda { false }).active?.should == false
    end

    it 'should return false when not all conditions are met (only static)' do
      RubyFlipper::Feature.new(:feature_name, false, true).active?.should == false
    end

    it 'should return true when all conditions are met' do
      RubyFlipper::Feature.new(:feature_name, true, true).active?.should == true
    end

  end

  describe '.condition_met?' do

    context 'with a symbol' do

      it 'should return the active? of the referenced feature' do
        RubyFlipper::Feature.add(:referenced, true)
        RubyFlipper::Feature.condition_met?(:referenced).should == true
      end

      it 'should raise an error when the referenced feature is not defined' do
        lambda { RubyFlipper::Feature.condition_met?(:missing) }.should raise_error RubyFlipper::FeatureNotFoundError, 'feature missing is not defined'
      end

    end

    {
      true       => true,
      'anything' => true,
      false      => false,
      nil        => false
    }.each do |condition, expected|

      it "should call a given proc and return #{expected} when it returns #{condition}" do
        RubyFlipper::Feature.condition_met?(lambda { condition }).should == expected
      end

      it "should call anything callable and return #{expected} when it returns #{condition}" do
        RubyFlipper::Feature.condition_met?(stub(:call => condition)).should == expected
      end

      it "should return #{expected} when the condition is #{condition}" do
        RubyFlipper::Feature.condition_met?(condition).should == expected
      end

    end

    context 'with a complex proc' do

      it 'should return the met? of the combined referenced conditions' do
        RubyFlipper::Feature.add(:true, true)
        RubyFlipper::Feature.add(:false, false)
        RubyFlipper::Feature.condition_met?(lambda { active?(:true) || active?(:false) }).should == true
        RubyFlipper::Feature.condition_met?(lambda { active?(:true) && active?(:false) }).should == false
      end

    end

  end

end
