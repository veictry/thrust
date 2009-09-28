#include <thrust/random/linear_congruential_engine.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/transform_reduce.h>

#include <iostream>

// we could vary M & N to find the perf sweet spot

__host__ __device__
unsigned int hash(unsigned int a)
{
    a = (a+0x7ed55d16) + (a<<12);
    a = (a^0xc761c23c) ^ (a>>19);
    a = (a+0x165667b1) + (a<<5);
    a = (a+0xd3a2646c) ^ (a<<9);
    a = (a+0xfd7046c5) + (a<<3);
    a = (a^0xb55a4f09) ^ (a>>16);
    return a;
}

struct estimate_pi
{
  __host__ __device__
  float operator()(unsigned int thread_id)
  {
    using namespace thrust::experimental::random;

    float sum = 0;
    unsigned int N = 10000; // samples per thread

    unsigned int seed = hash(thread_id);

    // seed a random number generator
    // XXX use this with uniform_01
    minstd_rand rng(seed);

    // take N samples in a quarter circle
    for(unsigned int i = 0; i < N; ++i)
    {
      // draw a sample from the unit square
      float x = static_cast<float>(rng()) / minstd_rand::max;
      float y = static_cast<float>(rng()) / minstd_rand::max;

      // measure distance from the origin
      float dist = sqrtf(x*x + y*y);

      // add 1.0f if (u0,u1) is inside the quarter circle
      if(dist <= 1.0f)
        sum += 1.0f;
    }

    // multiply by 4 to get the area of the whole circle
    sum *= 4.0f;

    // divide by N
    return sum / N;
  }
};

int main(void)
{
  // use 30K independent seeds
  int M = 30000;

  float estimate = thrust::transform_reduce(thrust::counting_iterator<int>(0),
                                            thrust::counting_iterator<int>(M),
                                            estimate_pi(),
                                            0.0f,
                                            thrust::plus<float>());
  estimate /= M;

  std::cout << "pi is around " << estimate << std::endl;

  return 0;
}

