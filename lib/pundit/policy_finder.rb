module Pundit
  # Finds policy and scope classes for given object.
  # @api public
  # @example
  #   user = User.find(params[:id])
  #   finder = PolicyFinder.new(user)
  #   finder.policy #=> UserPolicy
  #   finder.scope #=> UserPolicy::Scope
  #
  class PolicyFinder
    attr_reader :object

    # @param object [any] the object to find policy and scope classes for
    #
    def initialize(object)
      @object = object
    end

    # @return [nil, Scope{#resolve}] scope class which can resolve to a scope
    # @see https://github.com/elabs/pundit#scopes
    # @example
    #   scope = finder.scope #=> UserPolicy::Scope
    #   scope.resolve #=> <#ActiveRecord::Relation ...>
    #
    def scope
      policy::Scope if policy
    rescue NameError
      nil
    end

    # @return [nil, Class] policy class with query methods
    # @see https://github.com/elabs/pundit#policies
    # @example
    #   policy = finder.policy #=> UserPolicy
    #   policy.show? #=> true
    #   policy.update? #=> false
    #
    def policy
      klass = find(object)
      klass = klass.constantize if klass.is_a?(String)
      klass
    rescue NameError
      nil
    end

    # @return [Scope{#resolve}] scope class which can resolve to a scope
    # @raise [NotDefinedError] if scope could not be determined
    #
    def scope!
      raise NotDefinedError, "unable to find policy scope of nil" if object.nil?
      scope or raise NotDefinedError, "unable to find scope `#{find(object)}::Scope` for `#{object.inspect}`"
    end

    # @return [Class] policy class with query methods
    # @raise [NotDefinedError] if policy could not be determined
    #
    def policy!
      raise NotDefinedError, "unable to find policy of nil" if object.nil?
      policy or raise NotDefinedError, "unable to find policy `#{find(object)}` for `#{object.inspect}`"
    end

    # @return [String] the name of the key this object would have in a params hash
    #
    def param_key
      if object.respond_to?(:model_name)
        object.model_name.param_key.to_s
      elsif object.is_a?(Class)
        object.to_s.demodulize.underscore
      else
        object.class.to_s.demodulize.underscore
      end
    end

  private

    def find(subject)
      if subject.nil?
        nil
      elsif subject.is_a?(Array)
        modules = subject.dup
        last = modules.pop
        context = modules.map { |x| find_class_name(x) }.join("::")
        [context, find(last)].join("::")
      elsif subject.respond_to?(:policy_class)
        subject.policy_class
      elsif subject.class.respond_to?(:policy_class)
        subject.class.policy_class
      else
        klass = find_class_name(subject)
        "#{klass}#{SUFFIX}"
      end
    end

    def find_class_name(subject)
      if subject.respond_to?(:model_name)
        subject.model_name
      elsif subject.class.respond_to?(:model_name)
        subject.class.model_name
      elsif subject.is_a?(Class)
        subject
      elsif subject.is_a?(Symbol)
        subject.to_s.camelize
      else
        subject.class
      end
    end
  end
end
